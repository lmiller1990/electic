Explore Testing Library, a framework agnostic library for testing applications in a user centric manner.

[`testing-library`](https://testing-library.com/) is a framework agnostic library for testing web application. 

It asserts that it is:

- Simple and complete testing utilities that encourage good testing practices
- Tests only break when your app breaks, not implementation details
- Interact with your app the same way as your users

Let's write some tests, and see how it compares to Vue Test Utils (VTU). Testing Library has a very different philosophy to Vue Test Utils. Testing Library has many integrations, including a Vue specific one, which actually uses Vue Test Utils internally, but that's an implementation detail, which isn't really relevant to how you write your tests using Testing Library.

## Getting Started.

At the time of this post, there is no Vue 3 support in Testing Library, so we will proceed using Vue 2. I cloned their Vue integration repository, found [here](https://github.com/testing-library/vue-testing-library), and ran `npm install`. There are lots of examples here. I also installed VTU with `npm install @vue/test-utils`.

## The Component

I'll be using the following simple component, `MyInput.vue`. It is an input with a `rules` prop for some basic validation relating to the length of the input.

```vue
<template>
  <div>
    <label :for="name">{{ name }}</label>
    <input v-model="value" @input="$emit('input', $event.target.value)" :id="name" />
    <div v-if="error">{{ error }}</div>
  </div>
</template>

<script>
export default {
  props: {
    value: {
      type: String,
      required: true
    },

    name: {
      type: String,
      required: true
    },

    rules: {
      type: Object,
      default: {}
    }
  },

  computed: {
    error() {
      if (this.rules.min && this.value.length < this.rules.min) {
        return `Error: ${this.name} is too short`
      }

      if (this.rules.max && this.value.length > this.rules.max) {
        return `Error: ${this.name} is too long`
      }
    }
  }
}
</script>
```

Very standard stuff. If the input length is less than or greater than the `rules` we specify, an error is rendered. 

## Testing with Vue Test Utils

There are a few ways you can test this. We will want to cover three cases: no error, input is too short, and input it too long. One way to accomplish this is as follows:

```js
describe('MyInput', () => {
  it('renders an error when input is too long', () => {
    const wrapper = mount(MyInput, {
      propsData: {
        value: '123456789',
        name: 'username',
        rules: {
          min: 1,
          max: 5
        }
      }
    })

    expect(wrapper.html()).toContain('Error: username is too long')
  })
})
```

We just mount the component in the state we expect, and make assertions. To cover the other two cases - you can just copy and paste the test, or make them a bit more readable using a factory function, described in my [Reducing Duplication in Tests](/blog/reducing-duplication-in-tests) article.

Another way it to test them all in one way, with interaction. Both are valid, this one gets you a bit closer to how are user would use the component:

```js
describe('MyInput', () => {
  it('renders successfully', async () => {
    const wrapper = mount(MyInput, {
      propsData: {
        value: 'asdf',
        name: 'username',
        rules: {
          min: 1,
          max: 10
        }
      }
    })

    expect(wrapper.html()).not.toContain('Error')

    await wrapper.find('input').setValue('asdfasdfasdf')
    expect(wrapper.html()).toContain('Error: username is too long')

    await wrapper.find('input').setValue('')
    expect(wrapper.html()).toContain('Error: username is too short')
  })
})
```

This is also closer to the Testing Library philosophy - "Interact with your app the same way as your users".

## Testing with Testing Library

Now, let's see the same test, but with Testing Library. Because it uses VTU internally, some of the same mounting options are supported, such as `propsData`. I'm going to demonstrate another way to write this test, though, which I believe is more "in the spirit" of Testing Library, which is using a Parent component. Testing Library tests tend to use mounting options much less than VTU tests. Most of the other integrations, like React Testing Library, don't even support mounting options, other than props.

With this in mind, you can mount your component like this:

```js
describe('MyInput with testing library', () => {
  it('renders successfully', async () => {
    const Parent = {
      components: { MyInput },
      data() {
        return { username: '1234' }
      },
      template: `<MyInput v-model="username" name="username" :rules="{ min: 3, max: 10 }" />`
    }
  })
})
```

The reason mounting using a Parent component is useful is because, as your app grows, you will likely find yourself using `MyInput.vue` to compose forms. When I test my forms, I have found this pattern to be very useful. You might end up with something like:

```js
const Parent = {
  components: { MyInput },
  data() {
    return {
      username: '',
      password: ''
    }
  },
  template: `
    <MyForm>
      <MyInput v-model="username" name="username" :rules="{ min: 5, max: 10 }" />
      <MyInput v-model="password" name="password" :rules="{ min: 8, max: 16 }" />
    </MyForm>
  `
}
```

Testing Library encourages you to test like your users, and lends itself well to larger, "end to end" style tests.

## Assertions and Queries with Testing Library

Now we have mounted our component, let's get to interacting. Instead of `mount`, we do `render`. `render` takes the component as the first argument, and returns the **screen**.

```js
describe('MyInput with testing library', () => {
  it('renders successfully', async () => {
    const Parent = {
      components: { MyInput },
      data() {
        return { username: 'username' }
      },
      template: `<MyInput v-model="username" name="username" :rules="{ min: 3, max: 10 }" />`
    }
  })
  
  const screen = render(Parent)
})
```

If you do a `console.log` on `screen`, you get a bunch of methods:

```
{
      container: HTMLDivElement {},
      baseElement: HTMLBodyElement {},
      debug: [Function: debug],
      unmount: [Function: unmount],
      isUnmounted: [Function: isUnmounted],
      html: [Function: html],
      emitted: [Function: emitted],
      updateProps: [Function: updateProps],
      queryAllByLabelText: [Function: bound queryAllByLabelText],
      getAllByLabelText: [Function: bound getAllByLabelText],
      queryByLabelText: [Function: bound ],
      getByLabelText: [Function: bound ],
      findAllByLabelText: [Function: bound ],
      
      // ...
}
```

The are all listed [here](https://testing-library.com/docs/dom-testing-library/api-queries#screendebug). Basically, there are three ways to find elements:

- getByXXX
- queryByXXX
- findByXXX

`getBy` throws an error if nothing is found. `queryBy` will just return null. `findBy` is async, and will wait for a default of 1000ms before failing - this is useful for DOM nodes that might not appear immediately, a common occurrence in Vue, where the DOM is updated asynchronously.

With that in mind, we can start by asserting no error is found. Testing Library supports, and seems to encourage the use of regular expressions. The reason for this that querying by a specific DOM element is against their philosophy - users don't care about DOM elements, they care about what they can see. Regular expressions are a way to approximate this. So, we end up with this query:

```js
expect(queryByText(/Error/)).not.toBeInTheDocument()
```

We are asserting no error, since the default value, `username`, is in the limits we set of 3-10 characters.

Testing Library includes some extra assertions, like `toBeInTheDocument`. While VTU and Testing Library accomplishthe same thing via `wrapper.find` and `queryByText`, they are very different approaches:

- Vue Test Utils is **component centric**. We interact with and make assertions on the **component**.
- Testing Library is **user centric**. We interact using methods that have no relation to the component, since the user doesn't know or care about those.

## Interactions with Testing Library

Interactions take a similar approach in Testing Library. Instead of using `trigger` or `setValue`, we can update the input like this:

```
await fireEvent.update(getByLabelText(/username/, { selector: 'input' }), 'this is a long username')
expect(queryByText(/too long/)).toBeInTheDocument()
```

Notice we are not concerned with components; we query by the label, which is something the user would do (they literally query, using their eyes, for a "username" label). Clicking on a `<label>` with a `for="username"` attribute will select the related `<input>` by the matching `id`, so Testing Library replicates this by allowing an additional `selector` option. We then assert the error using the regular expression syntax introduced previously, which is user centric, not component centric.

## Discussion and Conclusion

I still think VTU has it's place. It's good for testing individual comoponents, especially ones with many edge cases. I will continue to use it for my personal component library, for example. Testing Library is very useful for user tests, where we are verifying the behavior and public API for our application. You could even use both in the same application; you should use the best tool for the job, whatever you decide that might be.

For my next application, I plan to try using Testing Library exclusively, and see how it things go. Testing Library can do lots of other things I haven't discussed, you can learn more [here](https://testing-library.com/) on their official homepage. You can find the Vue integration and docs [here](https://testing-library.com/docs/vue-testing-library/intro), which is maintained by one of the maintainers of VTU, [Adri Fontcu](https://twitter.com/afontq).
