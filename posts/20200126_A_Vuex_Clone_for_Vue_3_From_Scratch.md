Vue 3's alpha has been out for a while now, however most of the core libraries have not caught up yet - namely Vuex and Vue Router. Vuex, in particular, is fairly simple to implement with the new APIs exposed by Vue, namely `reactive` and `computed`. In this article, we will build a Vuex replacement (let's called it Hackex). 

To keep things simple, we will only implement root level `state`, `actions`, `getters` and `mutations` - no namespaced `modules` for now, although I'll provide a hint on how to accomplish that as well. 

The source code and tests in this article can be found [here](https://gist.github.com/lmiller1990/a6afeef04cec494cee4abb6ec3c305bb).

## Specification

We will write the code to enable the following:


```js
const store = new Vuex.Store({
  state: {
    count: 0
  },
  mutations: {
    INCREMENT(state, payload) {
      state.count += payload
    }
  },
  actions: {
    increment(context, payload) {
      context.commit('INCREMENT', payload)
    }
  },
  getters: {
    triple(state) {
      return state.count * 3
    }
  }
})
```

The only caveat is that at the time of this article, there is no way to attach a `$store` to `Vue.prototype`, so instead of `this.$store` we will use `window.store`. Since Vue 3 exposes it's reactivity separately from it's component and templating system we can use functions like `reactive` and `computed` to build a Vuex store, and unit test it entirely without even mounting a component. This works out well for us, since Vue Test Utils doesn't have support for Vue 3 yet.

## Getting Started

We will do this unit TDD, as usual. We only need to install two things: `vue` and `jest`. Install them with  `yarn add vue@3.0.0-alpha.1 babel-jest @babel/core @babel/preset-env`. Some basic config is needed - see the repository to get it. 

## Reactive State

The first test is related to the `state`:

```js
test('reactive state', () => {
  const store = new Vuex.Store({
    state: {
      count: 0
    }
  })
  expect(store.state).toEqual({ count: 0 })
  store.state.count++
  expect(store.state).toEqual({ count: 1 })
})
```

Of course this fails - Vuex is undefined. Let's define it:

```js
class Store {
}

const Vuex = {
  Store
}
```

Now we get `Expected: {"count": 0}, Received: undefined`. Let's grab `reactive` from `vue` and make it pass!

```js
import { reactive } from 'vue'

class Store {
  constructor(options) {
    this.state = reactive(options.state)
  }
}
```

So easy with Vue's `reactive` function. We are directly modifying `store.state` in the test - this isn't exactly ideal, so let's add a mutation to let us modify it that way instead.

## Implementing Mutations and Commit

As above, let's write the test first:

```js
test('commits a mutation', () => {
  const store = new Vuex.Store({
    state: {
      count: 0
    },
    mutations: {
      INCREMENT(state, payload) {
        state.count += payload
      }
    }
  })
  store.commit('INCREMENT', 1)
  expect(store.state).toEqual({ count: 1 })
})
```

Test is failing, as it should be. It fails with `TypeError: store.commit is not a function`. Let's implement `commit`, as well as assign `options.mutations` to `this.mutations` so we have access to them inside `commit`.:

```js
class Store {
  constructor(options) {
    this.state = reactive(options.state)
    this.mutations = options.mutations
  }

  commit(handle, payload) {
    const mutation = this.mutations[handle]
    if (!mutation) {
      throw Error(`[Hackex]: ${handle} is not defined`)
    }

    mutation(this.state, payload)
  }
}
```

Since `mutations` is just an object mapping properties to functions, we can just grab it using the `handle` argument, and call it, passing in `this.state`. We can also write a test for the case where the mutation is not defined:

```js
test('throws an error for a missing mutation', () => {
  const store = new Vuex.Store({ state: {}, mutations: {} })
  expect(() => store.commit('INCREMENT', 1)).toThrow('[Hackex]: INCREMENT is not defined')
})
```

## Dispatching and Action

`dispatch` is very similar to `commit` - both take the name of the function to call as a string as the first argument, and a payload for the second argument. Instead of receiving the `state`, though, an action receives a `context` object, which exposes `state`, `commit`, `getters` and `dispatch`. Also, `dispatch` will always returns a `Promise` - so `dispatch(...).then` should be valid. This means if the user's action does not return a Promise, or calling something that does like `axios.get`, we need to return one on behalf of the user.

With this in mind, we can write the following test:

We can write a test as follows. You may notice the tests getting repetitive - we can clean that up later with some factory functions.

```js
test('dispatches an action', async () => {
  const store = new Vuex.Store({
    state: {
      count: 0
    },
    mutations: {
      INCREMENT(state, payload) {
        state.count += payload
      }
    },
    actions: {
      increment(context, payload) {
        context.commit('INCREMENT', payload)
      }
    }
  })

  store.dispatch('increment', 1).then(() => {
    expect(store.state).toEqual({ count: 1 })
  })
})
```

Running this now gives us `TypeError: store.dispatch is not a function`. We know from previously we need to assign the actions in the constructor too, so let's do both those things, as well as calling the `action` in the same way we called the `mutation` earlier:

```js
class Store
  constructor(options) {
    // ...
    this.actions = options.actions
  }
  
  // ...
  dispatch(handle, payload) {
    const action = this.actions[handle]
    const actionCall = action(this, payload)
  }
}
```

Now we get `TypeError: Cannot read property 'then' of undefined`. This is, of course, because are are not return a `Promise` - we are not returning anything at all, in fact. We can check if the return value is a `Promise` like so, and if not, return one:

```js
class Store {
  // ...

  dispatch(handle, payload) {
    const action = this.actions[handle]
    const actionCall = action(this, payload)
    if (!actionCall || !typeof actionCall.then) {
      return Promise.resolve(actionCall)
    }
    return actionCall
  }
```

This isn't too different from how the real Vuex does it, see the source code [here](https://github.com/vuejs/vuex/blob/e0126533301febf66072f1865cf9a77778cf2176/src/store.js#L457). Now the test is passing!

## Implementing Getters with `computed`

Implementing `getters` is a bit more interesting. We also get to use the new `computed` method exposed by Vue. Let's write the test.

```js
test('getters', () => {
  const store = new Vuex.Store({
    state: {
      count: 5
    },
    mutations: {},
    actions: {},
    getters: {
      triple(state) {
        return state.count * 3
      }
    }
  })

  expect(store.getters['triple']).toBe(15)
  store.state.count += 5
  expect(store.getters['triple']).toBe(30)
})
```

As before, we get `TypeError: Cannot read property 'triple' of undefined`. This time, however, we cannot just do `this.getters = getters` in the `constructor` - we need to loop over them and ensure they are all using `computed` with `reactive` state. A simple but incorrect way would look like this:

```js
class Store {
  constructor(options) {
    // ...

    if (!options.getters) {
      return
    }

    for (const [handle, fn] of Object.entries(options.getters)) {
      this.getters[handle] = computed(() => fn(this.state)).value
    }
  }
}
```

`Object.entries(options.getters)` returns the `handle` (in this case `triple`) and the callback (the getter function) here. When we run the test, the first assertion `expect(store.getters['triple']).toBe(15)` passes. Because we are returning `.value`, however, we lose reactivity = `store.getters['triple']` is forever assigned a number. We want to return and call `computed` instead. We can accomplish this using `Object.defineProperty`, which lets us define a dynamic `get` method on an object. This is also how the real Vuex does this - see [here](https://github.com/vuejs/vuex/blob/e0126533301febf66072f1865cf9a77778cf2176/src/store.js#L269).

Our updated, working implementation is as follows:

```js
class Store {
  constructor(options) {
    // ...

    for (const [handle, fn] of Object.entries(options.getters)) {
      Object.defineProperty(this.getters, handle, {
        get: () => computed(() => fn(this.state)).value,
        enumerable: true
      })
    }
  }
}
```

Now it's working.

## Nested state with modules

To be fully compliant with the real Vuex, we need to implement modules. I won't do that here, since the article would be very long. Basically, you just need to recursively repeat the above process for each module, creating the namespace appropriately. Let's see how this might look for modules with nested `state`. The test looks like this:

```js
test('nested state', () => {
  const store = new Vuex.Store({
    state: {
      count: 5
    },
    mutations: {},
    actions: {},
    modules: {
      levelOne: {
        state: {},
        modules: {
          levelTwo: {
            state: { name: 'level two' }
          }
        }
      }
    }
  })

  expect(store.state.levelOne.levelTwo.name).toBe('level two')
})
```

We can implement this using some tricky recursion:

```js
const registerState = (modules, state = {}) => {
  for (const [name, module] of Object.entries(modules)) {
    state[name] = module.state
    if (module.modules) {
      registerState(module.modules, state[name])
    }
  }

  return state
}
```

Again, `Object.entries` is very useful here - we get the name of the module, and the content. If the module has `modules`, we just call `registerState` again on that module, passing in the previous module's state. This allows us to nest arbitrarily deep. When we hit the bottom level module, we just return the `state`. `actions`, `mutations` and `getters` are a tiny bit more involved. I may implement them in a future article.

We can update the `constructor` to use the `registerState` method, and all the tests are passing again. This is done before actions/mutations/getters, so they can have access to the entire state, which has been passed into `reactive`.

```js
class Store {
  constructor(options) {
    let nestedState = {}
    if (options.modules) {
      nestedState = registerState(options.modules, options.state)
    }
    this.state = reactive({ ...options.state, ...nestedState })

    // ..
  }
}
```

## Improvements

There are some features that we did not implement - namely:

- namespaced actions/mutations/getters for modules
- a plugin system
- ability to `subscribe` to mutations/actions (used mainly by plugins)

I may cover these in a future article, but it's not too difficult to implement them. They make good exercises for the motivated reader.

## Conclusion

- Building reactive plugins for Vue is even easier with Vue 3's exposed reactivity system
- It is possible to build a reactive plugin entirely decoupled from Vue - we didn't once render a component or open a browser, but we can be confident the plugin works correctly, in both a web and non-web environment (eg Weex, NativeScript, whatever else the Vue community dreams up)


