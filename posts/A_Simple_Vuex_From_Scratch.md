Build a simple Vuex implementation from scratch, in just 40 lines of code, complete with a reactive state and mutations.

The source code for this implementation is so minimal in can be found in an entire gist, located [here](https://gist.github.com/lmiller1990/8a5cea45752e3692281b72ce08722b0b). Published on 6/8/2018.

## Creating a global `store` object

Let's start by fleshing out the public API. We will let a user register the store using `Vue.use(Store)`. The actual store will be created using `new Store`, that takes an initial state and an object containing mutations. 

Let's start creating and installing the store plugin. Vuex plugins are just objects that expose a `install` method, which receives the Vue instance as the first argument. I want to allow users to inject the store using the same API as Vuex:

```js
new Vue({
  el: "#app",
  store
})
```

Values or objects passed to a Vue instance using the above syntax are exposed by `this.$options`. We can access the store by using `this.$options.store`, then assign it to a global `$store` property in the `beforeCreate` lifecycle method. Create a `store.js` file and add the following:

```js
class Store {
  static install(Vue) {
    Vue.mixin({
      beforeCreate() {
        this.$store = this.$options.store 
      }
    })
  }
}
```

By using a `mixin`, all child Vue components will have the store added to their instance and made available using `$store`.

Let's try it out with Vue. Creating the following `index.html`:

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/vue/2.5.17/vue.js"></script>
<script src="store.js"></script>
```

Add add the following minimal Vue app to `store.js`:

```js
document.addEventListener("DOMContentLoaded", () => {
  const el = document.createElement("div")
  el.id = "app"
  document.body.appendChild(el)

  Vue.use(Store)
  const store = new Store()

  window.app = new Vue({ el, store })
})
```

Open `index.html`, and `console.log(app.$store)` should show a empty `Store` object.

## Adding a reactive global state

Now we have a global store object, let's add the state. First, update the `store` class, adding a constructor that receives an object containing a `state` property. We will take advantage of the fact that all Vue components share the same `data` as the original Vue instance, and assign the `state` to a `$$state` variable. The `$$` simply represents a private variable - since Vue uses `$` to denote values attached to the prototype, I am using `$$` to simply convey this is a not part of the library's public API.

```js
class Store {
  // ...
  constructor({ state }) {
    this.vm = new Vue({
      data() {
        return { $$state: state }
      }
    })
  }
}
```

Lastly, when the user calls `$store.state`, we should return the `$$state` we just assigned. We can do so using a JavaScript `getter`:

```
class Store {
  // ...

  get state() {
    return this.vm.$data.$$state
  }
}
```

Update the minimal Vue app so the store instance receives an initial state, and the Vue app has a template that renders the state:

```js
document.addEventListener("DOMContentLoaded", () => {
  const el = document.createElement("div")
  el.id = "app"
  document.body.appendChild(el)

  Vue.use(Store)
  const store = new Store({ state: { count: 0 } })

  window.app = new Vue({ 
    el, 
    store,
    template: `
      <div>{{ $store.state.count }}</div>
    `
  })
})
```

If everything went well, you should see 0 rendered!

## Implementing Mutations

Now the store has a `state`, but no way to update it. Let's implement mutations. First, update the `constructor` to receive `mutations`:

```js
class Store {
  // ...

  constructor({ state, mutations }) {
    this.mutations = mutations

    // ...
  }

  // ...
}
```

Create an `increment` mutation and pass it to the instance of the store:

```js
// ...
document.addEventListener("DOMContentLoaded", () => {
  const mutations = {
    increment(state, { amount }) {
      state.count = state.count + amount
    }
  }

  const store = new Store({ state: { count: 0 }, mutations })
 
   // ...
})
```

Now we need a way to call the mutation. Add a `commit` method to the `Store` class:

```js
commit(handler, payload) {
  this.mutations[handler](this.state, payload)
}
```

This will get the correct mutations using the `handler`, and pass the state and payload as arguments. For example, `commit('increment', { amount: 1 })` will call `mutations['increment']`, passsing the `state` and the `payload`.

The last thing to do is update the `template` to actually commit a mutation:

```js
window.app = new Vue({ 
  el, 
  store,
  template: `
    <div>
      {{ $store.state.count }}
      <button @click="$store.commit('increment', { amount: 1 })">
        Increment
      </button>
    </div>
  `
})
```

If you did everything correctly, click the button should increment `count` by 1.

## Conclusion

This article covered a lot of interesting things:

- using `install` to initialize a plugin, and extend child components with `Vue.mixin`
- accessing an object passed to a newly created `Vue` instance with `this.$options.store`
- using a JavaScript `getter` to return a specific object when a property is accessed

I did not implement `actions`, but doing so is similar to mutations. You probably want to return a `Promise`, and perhaps use `bind` and pass a reference to `commit`, so you can update the state from an action by committing a mutation.

The source code for this implementation is so minimal in can be found in an entire gist, located [here](https://gist.github.com/lmiller1990/8a5cea45752e3692281b72ce08722b0b).
