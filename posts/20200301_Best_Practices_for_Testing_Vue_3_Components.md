In this article, we will look at what I consider to be best practices when writing tests for Vue components. We will also take a sneak-peak at the new version of Vue Test Utils, built in TypeScript for Vue 3. 

To do this, I will be building a simple Todo app, and writing tests for the features as we go.

## Getting Started

We get started with a minimal `App.vue`:

```html
<template>
  <div>
  </div>
</template>

<script lang="ts">
import { ref } from 'vue'

export interface Todo {
  id: number
  text: string
  completed: boolean
}

export default {
  setup() {
    const todos = ref<Todo[]>([
      {
        id: 1,
        text: 'Learn Vue.js 3',
        completed: false
      }
    ])

    return {
      todos
    }
  }
}
</script>
```

The `<template>` is currently empty - we will write a failing test before we work on that. Other than that, everything is pretty standard - since we are using TypeScript, we are able to type the `ref` using a `Todo` interface, which makes the content of a Todo much more clear to the reader.

## A best practice: `data-test` selectors 

Let's write the first test. We want to verify the `todos` are rendered.

```ts
test('renders a todo', () => {
  const wrapper = mount(App)

  expect(wrapper.find('[data-test="todo"]').text()).toBe('Learn Vue.js 3')
})
```

I am searching for the `todo` item is a `data-test` selector. I have found these really useful - things like classes and ids are prone to changing over time. By adopting a `data-test` convention, it's clear to other developers those tags are used for tests, and they should not be changed or removed.

Of course this test is failing - let's get it to pass.

```html
<template>
  <div>
    <div v-for="todo in todos" :key="todo.id" data-test="todo">
      {{ todo.text }}
    </div>
  </div>
</template>
```

## Completing a Todo

The next feature I'll be implementing is the ability to complete a todo. Let's write a test first.

```ts
test('can complete a todo', async () => {
  const wrapper = mount(App)
  expect(wrapper.find('[data-test="todo"]').classes())
    .not.toContain('completed')

  await wrapper.find('[data-test="todo-checkbox"]').setChecked(true)

  expect(wrapper.find('[data-test="todo"]').classes()).toContain('completed')
})
```

Again, we are using the `data-test` selector. We also see a new feature to the latest version of Vue Test Utils - we are now able to `await` any method that might cause the DOM to rerender, such as `setChecked`. We need to do this because Vue renders asynchronously, and if we do not `await`, it is possible our assertion is called before the DOM has updated.

I am asserting that the `class` contains `completed` - using some CSS, I can show which todos are completed by using the `completed` class and some styling, such as `text-decoration: strike-through;`.

Let's get this test to pass. We just need to update `<template>`:

```html
<template>
  <div>
    <div 
      v-for="todo in todos" 
      :key="todo.id" 
      :class="[ todo.completed ? 'completed' : '' ]"
      data-test="todo"
    >
      {{ todo.text }}
      <input 
          v-model="todo.completed" 
          type="checkbox" 
          data-test="todo-checkbox" 
        />
    </div>
  </div>
</template>
```

## Adding a new Todo

The last feature we will be adding, and subsequently refactoring, is a form that lets a user add a new todo. As usual, let's write a test that will help us think about how we want to implement the feature.

```ts
test('can create a new todo', async () => {
  const wrapper = mount(App)
  expect(wrapper.findAll('[data-test="todo"]')).toHaveLength(1)

  wrapper.find<HTMLInputElement>('[data-test="new-todo"]')
    .element.value = 'New Todo'
  await wrapper.find('[data-test="form"]').trigger('submit')

  expect(wrapper.findAll('[data-test="todo"]')).toHaveLength(2)
})
```

Since this test is mostly concerned with the number of todos (increasing from 1 to 2) we are focusing our assertions on the number of todos rendered. At this point, my test is not only failing, it's not even compiling - `ts-jest` is reporting an error:

```
tests/App.spec.ts:26:14 - error TS2339: Property 'value' does not exist on type 'Element'.

  26     .element.value = 'New Todo'
```

At first this is confusing. I intend on using an `<input>` element for the user to type the new todo - and of course an `<input>` element has a `value` property - so why is this error appearing?

The reason is that even though *we* know that `data-test="new-todo"` will refer to an `<input>` element, TypeScript does *not*. For this reason, `find` is generic in the newest version of Vue Test Utils - the signature looks like this: `find<T>(selector: string) => T`. We can hint at what `find` should return. Updating that line looks like this:

```ts
wrapper.find<HTMLInputElement>('[data-test="new-todo"]')
  .element.value = 'New Todo'
```

Now we can get suggestions for the properties on `element` from the IDE. Great!

Now our test is compiling (and failing), let's actually implement the feature. Only the new code is shown for brevity:

```html
<template>
  <div>
    <div 
      v-for="todo in todos" 
    >
      <!-- ... -->
    </div>
    <form @submit="createTodo" data-test="form">
      <input v-model="newTodo" data-test="new-todo" />
    </form>
  </div>
</template>

<script lang="ts">
import { ref } from 'vue'

// ...

export default {
  setup() {
    // ...
    const newTodo = ref('')
    const createTodo = () => {
      const todo: Todo = {
        id: todos.value.length + 1,
        text: newTodo.value,
        completed: false
      }
      todos.value.push(todo)
    }


    return {
      todos,
      newTodo,
      createTodo
    }
  }
}
</script>
```

Nothing especially unusual - we can see TypeScript and the `Todo` interface assisting us, ensuring we do not miss any properties in the new todo. With this code, everything is passing.

## Refactoring the new todo component

We are going to do a refactor, that will reveal some interesting facts about our tests. Let's imagine we now need to persist new todos to a server, so we want to make an API call when we submit the form. Since the form is getting complex, and may continue to do so, we decide to move to it's own component, `TodoForm.vue`. Let's move the logic from `App.vue` to `TodoForm.vue`:

```html
<template>
  <form data-test="form" @submit="createTodo">
    <input data-test="new-todo" v-model="newTodo" />
    <input type="submit" />
  </form>
</template>

<script>
import { ref } from 'vue'

export default {
  name: 'TodoForm',
  
  setup(props, ctx) {
    const newTodo = ref('')
    const createTodo = () => {
      const todo = {
        id: -1,
        text: newTodo.value,
        completed: false
      }
      ctx.emit('createTodo', todo)
    }

    return {
      createTodo,
      newTodo
    }
  }

}
</script>
```

The only real change is instead of `todos.value.push` to add the new todo to the array, we are using `ctx.emit` to emit a `createTodo` event with the new todo at the first parameter. We set `-1` to the `id` temporarily, since we do not know the length of the `todos` array in this component.

The test is now failing - let's import the new `TodoForm.vue` component, and see what happens. Again, only the changed code is shown:

```html
<template>
  <div>
    <! -- ... -->
    <TodoForm @createTodo="createTodo" />
  </div>
</template>

<script lang="ts">
import { ref } from 'vue'
import TodoForm from './TodoForm.vue'

// ...

export default {
  components: {
    TodoForm,
  },

  setup() {
    // ...

    return {
      todos,
      createTodo
    }
  }
}
</script>
```

We basically just removed the `<form>` and replaced it with `<TodoForm />` - and all the tests are passing again. This is a *very good* thing - since the behavior did not change, the tests should not need to change either. If a refactor breaks your tests, it (usually) means you are testing implementation details, not behavior. The user doesn't care about how things work, they care that they work correctly, so that's what your tests should reflect.

Even though we don't have a server to run the code, we could go ahead and implement the posting of a new todo to a server. Let's do that - `TodoForm.vue` setup function now looks like this:

```ts
setup(props, ctx) {
  const newTodo = ref('')
  const createTodo = async () => {
    const todo = {
      id: -1,
      text: newTodo.value,
      completed: false
    }
    const response = axios.post('/todos', {
      todo
    })
    ctx.emit('createTodo', response.data)
  }

  return {
    createTodo,
    newTodo
  }
}
```

The test is now failing with all sorts of errors. Let's mock out axios with `jest.mock` at the top of our test:

```ts
jest.mock('axios', () => ({
  post: () => ({
    data: {
      id: 2,
      text: 'Do work',
      completed: false
    }
  })
}))
```

The test is green again - great! We could even update the test to verify that `Do work` is now rendered as the second todo, if we wanted.

## Discussion and Conclusion

This article covered a few best practices, namely:

- using `data-test` selectors in tests
- testing behaviors, not implementations

One thing you may have noticed is we have *no* tests for `TodoForm.vue` - this is intentional. We test is implicitly via the tests for `App.vue`. If `TodoForm.vue` grew in complexity, I would consider writing specific tests for some of its more complex behavior - but I would still keep the tests we just wrote, since those cover the integration between the two components. This gives me confidence my system is working correctly.
