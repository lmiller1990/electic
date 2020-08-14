Vue has a pair of functions, `provide` and `inject`, making it easy to utilize dependency injection, making it easy to have a globally accessible object (such as a router or a flux store) as well as making it easy to test components in isolation. Let's see how `provide` and `inject` work with an example, some of the things to look out for, then upgrade an existing by writing a `useStore` composable to make a reactive store available in all the components.

## A Simple Example

Let's start with a simple example: an `A` component which renders a color, accessed via `provide`. We will use render functions, instead of a single file component, since that way we can write multiple components in a single file.

```ts
import { provide, inject, h } from 'vue'
import { mount } from '@vue/test-utils'

const A = {
  setup () {
    const color = inject('color')
    return () => [
      h('div', { id: 'a' }, `Color is ${color}`)
    ]
  }
}

const App = {
  setup() {
    provide('color', 'red')
    return () => [
      h(A)
    ]
  }
}

test('dep. injection', () => {
  const wrapper = mount(App)
  console.log(wrapper.html())
})
```

This renders `<div id="a">Color is red</div>`. You might have noticed We are returning an Array from our render functions - this will render a fragment, something Vue 3 has no problem doing with, whether you are using a SFC or an inline render function. When you call `inject`, Vue will look for the nearest component above where `inject` was called and find the corresponding `provide`. If one isn't found, you get a warning.

In this case, we called `provide` in `App`, so everything works as expected. Let's add another component, `B`, and see what else `provide` and `inject` can do:

```ts
import { provide, inject, h } from 'vue'
import { mount } from '@vue/test-utils'

const A = {
  setup () {
    const color = inject('color')
    provide('color', 'blue')
    return () => [
      h('div', { id: 'a' }, `Color is ${color}`),
      h(B)
    ]
  }
}

const B = {
  setup () {
    const color = inject('color')
    return () => h('div', { id: 'b' }, `Color is ${color}`)
  }
}

const App = {
  setup() {
    provide('color', 'red')
    return () => [
      h(A)
    ]
  }
}

test('dep. injection', () => {
  const wrapper = mount(App)
  console.log(wrapper.html())
})
```

Now we get `<div id="a">Color is red</div><div id="b">Color is blue</div>`. The reason `B` is rendering `blue` is because the nearest `provide` call, inside of `A`, sets `color` to `blue`. If this seems confusing, that's because it is. You can imagine a large application with 10s or 100s of components - it might be difficult to track down where a specific value is provided. While `provide` and `inject` are pretty neat, use them sparingly.

## A Real World Example

In some previous articles, I created a kanban board with a reactive store. The full [source code is here](https://github.com/lmiller1990/graphql-rest-vue), you probably will want to have a look at it as you read through this article to see the changes in context. 

You can find the first article in that series [here](https://vuejs-course.com/blog/jira-kanban-board-with-typesafe-graphql-part-1), and the article where I create the store [here](https://vuejs-course.com/blog/jira-kanban-board-with-typesafe-graphql-part-4). Let's go ahead an upgrade that to use `provide` and `inject` to make the store available (I was simply doing `import { store } from './store'`, which isn't ideal for a few reasons). 

Before we make the change, let's see *why* this is an improvement. I will first update the store, in `src/frontend/store.ts`:

```ts
import { reactive, inject, provide } from 'vue'
import { SelectProject, CurrentProject, FetchProject } from './types'

interface State {
  projects: SelectProject[]
  currentProject?: CurrentProject
  count: number
}

function initialState(): State {
  return {
    projects: [],
    count: 0
  }
}

export class Store {
  protected state: State

  constructor(init: State = initialState()) {
    this.state = reactive(init)
  }

  increment() {
    this.state.count += 1
  }

  // ...

}

export const store = new Store()
```

We have a basic `count` that can be updated with `increment`. Update `src/frontend/App.vue` to use those:

```html
<template>
  <select-project :projects="projects" v-model="selectedProject" />
  Count: {{ count }}
  <div class="categories">
    <category
      v-for="category in categories"
      :key="category.id"
      :category="category"
      :tasks="getTasks(category)"
    />
  </div>
</template>

<script lang="ts">
import { defineComponent, computed, ref, watch } from 'vue'
import { store } from './store'
import SelectProject from './SelectProject.vue'
import Category from './Category.vue'
import { Category as ICategory, Task } from './types'

export default defineComponent({
  components: {
    SelectProject,
    Category
  },

  setup() {
    const store = useStore()
    store.increment()

    // ...

    return {
      count: computed(() => store.getState().count),
      projects: computed(() => store.getState().projects),
      categories: computed(() => store.getState().currentProject?.categories),
      selectedProject,
      getTasks
    }
  }
})
</script>
```

Finally, add two tests to `src/frontend/App.spec.ts`:

```ts
import { mount, flushPromises } from '@vue/test-utils'
import App from './App.vue'

// ...

test('App', async () => {
  const wrapper = mount(App)
  expect(wrapper.html()).toContain('Count: 1')
})

test('App', async () => {
  const wrapper = mount(App)
  expect(wrapper.html()).toContain('Count: 1')
})
```

Yep - the same test, should both be passing, right? Wrong! Running these tests shows the first one passes, but the second one fails: the DOM now contains `Count: 2`. The reason is we are using the *same* store instance for both tests! When we did `store.increment()` in the first test, we increased the `count` to 1, and it stayed that way for the second test. This is called *cross test contamination*. 

What we need is some way to have a fresh store for each test. 

## A useStore composable

Let's create a `useStore` function, which will inject the store into each component. Update `store.ts`:

```ts
import { reactive, inject, provide } from 'vue'

// ...

export const store = new Store()

export const useStore = (): Store => {
  return inject('store')
}
```

Now we just need some way to provide the store to the application. Update `main.ts`:

```ts
import { createApp } from 'vue'
import App from './frontend/App.vue'
import { store } from './frontend/store'

const app = createApp(App)
app.provide('store', store)

app.mount('#app')
```

Now when a component calls `useStore`, it will find the nearest `provide('store')` call. We only have one, at the very top level of the application. Update `App.vue` and `Category.vue`:

```html
<template> 
  <!-- ... -->
</template>

<script lang="ts">
// ...
import { useStore } from './store'

export default defineComponent({
  setup() {
    const store = useStore()

    // ...
  }
})
```

That easy! The application is now working again, but is powered using `provide` and `inject`. Finally, we can fix the tests. Update `store.ts` to `export` the `class Store` so we can import it in the `App.spec.ts` file, then update the tests in `App.spec.ts`

```ts
import { mount, flushPromises } from '@vue/test-utils'
import App from './App.vue'
import { Store } from './store'

// ...

test('App', async () => {
  const wrapper = mount(App, {
    global: {
      provide: {
        store: store
      }
    }
  })
  expect(wrapper.html()).toContain('Count: 1')
})

test('App', async () => {
  const wrapper = mount(App, {
    global: {
      provide: {
        store: store
      }
    }
  })
  expect(wrapper.html()).toContain('Count: 1')
})
```

Now they both pass - we use the `global.provide` field to create and provide a new store instance for each test, eliminating the cross test contamination.

## Conclusion

This article explored `provide` and `inject`. When using these two functions

- Use them sparingly. Things can get confusing.
- You may provide different values using the same key to components depending on the nearest ancestor that calls `provide`.
- It is idiomatic to call `inject` inside a `useXXX` function. These are sometimes called "hooks" or "composables", but they are just functions that call `inject`.
- You can use `provide` and `inject` to avoid cross test contamination and make each test isolated.
