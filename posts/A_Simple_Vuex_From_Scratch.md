Build a simple Vuex implementation from scratch, in just 40 lines of code, complete with a reactivite state and mutations.

## Creating a global `store` object

Let's start by fleshing out the public API. We will let a user register the store using `Vue.use(Store)`. The actual store will be created using `new Store`, that takes an initial state and an object containing mutations. 

Let's start creating and installing the store plugin. Vuex plugins are just objects that expose a `install` method, which receives the Vue instance as the first argument. I want to allow users to inject the store using the same API as Vuex:

```js
new Vue({
  el: "#app",
  store
})
```

Values or objects passed to a Vue instance using the above syntaxc are exposed by `this.$options`. We can access the store by using `this.$options.store`, then assign it to a global `$store` object in the `beforeCreate` lifecycle method. Create a `store.js` file and add the following:

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

By using a `mixin`, all child Vue components will have the store mixed in to their instance and available using `$store`.

Let's try it out with Vue. Creating the following html:

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

`console.log(app.$store)` should show a empty `Store` object.

## Adding a reactive global state

Now we have a global store object, let's add the state. First, update the `store` class to have a constructor that receives an object containing a `state` object. We will take advantage of the fact that all Vue components share the same `data` as the original Vue instance, and assign the `state` to a `$$state` variable. The `$$` simply represents a private variable - since Vue uses `$` to denote values attached to the prototype, I am using `$$` to simply convey this is a not part of the public API for the library.

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

Lastly, when the user calls `$store.state`, we should return `$$state`. We can do so using a JavaScript `getter`:

```
class Store {
  // ...

  get state() {
    return this.vm.$data.$$state
  }
}
```

Update the minimal Vue app so thestore instance receives a base state, and the Vue app has a template that renders the state:

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
