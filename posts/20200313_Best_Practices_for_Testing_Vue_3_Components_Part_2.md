In this article, we continue developing the TodoApp from the previous post. 

Find it [here](/blog/best-practices-for-testing-vue-3-components) if you have not read it for the context. We will start by by moving the new todo form to a separate component, and seeing what a test might look like if the component was to persist a todo to a backend server via an API call.

## Creating a TodoForm component

Since the form is about to get a whole lot more complex, let's create a new component for it, `TodoForm.vue`, and move the markup from `TodoApp.vue` to it:

```html
<template>
  <form @submit="createTodo" data-test="todo-form">
    <input type="text" v-model="newTodo" data-test="todo-input" />
  </form>
</template>
```

In `TodoApp.vue`, we just import and render a `<TodoForm />`:

```html
<template>
  <div>
    <div
      v-for="todo in todos"
      :key="todo.id"
      data-test="todo"
      :class="[ todo.completed ? 'completed' : '' ]"
    >
      {{ todo.text }}

      <input type="checkbox" v-model="todo.completed" data-test="complete-checkbox" />
    </div>
    <TodoForm />
  </div>
</template>
```

All the test are now failing, since we need to move the business logic from the `TodoApp` to `TodoForm`. Let's do that.

`TodoApp.vue` now looks like this:

```html
<template>
  <div>
    <div
      v-for="todo in todos"
      :key="todo.id"
      data-test="todo"
      :class="[ todo.completed ? 'completed' : '' ]"
    >
      {{ todo.text }}

      <input type="checkbox" v-model="todo.completed" data-test="complete-checkbox" />
    </div>
    <TodoForm @createTodo="createTodo" />
  </div>
</template>

<script lang="ts">
import { ref } from 'vue'

import TodoForm from './TodoForm.vue'

interface Todo {
  id: number
  text: string
  completed: boolean
}

export default {
  components: {
    TodoForm
  },

  setup() {
    const todos = ref<Todo[]>([
      {
        id: 1,
        text: 'do some work',
        completed: false
      }
    ])
    const createTodo = (todo: Todo) => {
      todos.value.push(todo)
    }

    return {
      todos,
      createTodo,
    }
  }
}
</script>
```

And `TodoForm.vue`:

```html
<template>
  <form @submit="createTodo" data-test="todo-form">
    <input type="text" v-model="newTodo" data-test="todo-input" />
  </form>
</template>

<script lang="ts">
import { ref } from 'vue'

export default {
  setup(props, ctx) {
    const newTodo = ref('')
    const createTodo = () => {
      const todo: Todo = {
        id: 2,
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

The main change is `createTodo` in `TodoForm` now emits a `createTodo` event, which `TodoApp` then responds to. Now our tests are passing again. 

## A review of our tests

Notice we did **not** change the tests at any point - this is a VERY GOOD THING. Good tests operate on behavior, not implementation details. If you find yourself having to change your tests when you refactor your code, chances are, you are testing implementation details (aka, **how** the code works) rather than the public API and behavior (what the code actually does).

Since we did not change and features, just performed a refactor, we should not, and did not, change our tests. Great!

## Adding a test for TodoForm

Let's add a basic test for TodoForm. It will be similar to the TodoApp test, where we will out the form and submit it.

```ts
import { mount } from '../src'

import TodoForm from './TodoForm.vue'

const mockTodo = {
  id: 2,
  text: 'Test todo',
  completed: false
}

test('creates a todo', async (done) => {
  const wrapper = mount(TodoForm)

  wrapper.find<HTMLInputElement>('[data-test="todo-input"]').element.value = 'My new todo'
  await wrapper.trigger('submit')

  expect(wrapper.emitted().createTodo).toHaveLength(1)
  expect(wrapper.emitted().createTodo[0]).toEqual([ mockTodo ])
})
```

`emitted` is an object that maps all the events a component has emitted during its lifetime. Each key is an array, where each entry represents a single emitted event, and the parameters it emitted. We assert that one `createTodo` event was emitted, with a `mockTodo` parameter.

## Adding an API to TodoForm

Instead of just emitting a new todo, let's make an API call, persist it to a database, then emit the new todo. We can use `axios` to make the API call. The update `<script>` tag in `TodoForm.vue` looks like this:

```html
<script lang="ts">
import { ref } from 'vue'
import axios from 'axios'

import { Todo } from './App.vue'

export default {
  setup(props, ctx) {
    const newTodo = ref('')
    const createTodo = async () => {
      const todo: Todo = {
        id: 2,
        text: newTodo.value,
        completed: false
      }
      const response = await axios.post<Todo>('/api/todos', { todo })
      ctx.emit('createTodo', response.data)
    }

    return {
      createTodo,
      newTodo
    }
  }
}
</script>
```

Now the test will fail - we are making an API call in a test, which is not ideal. The API call is of course failing with a network error, so the event is not emitted. We can use `jest.mock` to fake out `axios`, and return our `mockTodo`:

```ts
jest.mock('axios', () => {
  return {
    default: {
      post: (url: string) => {
        return {
          data: mockTodo
        }
      }
    }
  }
})
```

And great! Our test now passes. 

## Reflecting on the TodoForm spec

At this point, some developers may feel proud of their `TodoForm` component - full tested, all green. Our `TodoApp` tests, on the other hand, are all failing - since we now are using `axios`, we need to mock it our there as well. So.... we go ahead and move the `jest.mock` to the other test. We are now repeating ourselves - we have the same mock to test the same behavior in multiple tests! We got so excited about using `emitted` and `jest.mock` that we did not stop and ask ourselves, *does this make sense*? 

In my opinion, no. The TodoForm component is as much an implementation detail as how we emit events, or now we add todos to an array. Of course, if it does get sufficiently complex, we may need to have lots of fine grained tests around it. Either way, we will still need to mock `axios` out in the `TodoApp` test, to make sure we are not triggering an API call in our test. Ideally, I would not bother with a dedicated test file for `TodoForm` until it gets too complex to test as part of the `TodoApp` component - which it is not, at least at the moment.

Another approach we could consider is, instead of `jest.mock('axios)` in the `TodoApp` test to prevent the API call, we could also mock out `TodoForm`: something like this would work:

```ts
jest.mock('./TodoForm.vue', () => ({
  render() {
    return h('div')
  }
}))
```

I don't find this as ideal though; I like to be able to test components and their interactions, which means a full `mount` and as little stubbing as possible.


## Conclusion

We refactored the `TodoApp` component's form and wrote some unit tests for it. Although they may not be strictly necessary now, we saw how to use `emitted` and `jest.mock` to test the `TodoForm.vue`. We also talked about the merits of mocking and stubbing, and how each has trade-offs. As always, the best decision will depend on your app and the problem you are solving. I'll be diving more into these topics, and look forward to discussing mocking vs stubbing, shallowMount vs mount and other opinions in a future article.
