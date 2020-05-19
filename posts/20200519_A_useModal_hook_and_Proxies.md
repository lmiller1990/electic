While working on my course, The Composition API, a very clean abstraction for handling modals using the composition API emerged in the form of a `useModal` hook. In this article we will build it from the ground up. 

The final API will look something like this:

```ts
// Installation
const app = createApp(App)
app.use(ModalPlugin)
app.$mount('#app')
```

```html
<!-- Usage -->
<template>
  <button @click="show">show</button>
  <teleport to="#modal-dest" v-if="visible">
    <modal-content-here />
  </teleport>
</template

<script lang="ts">
import { defineComponent } from 'vue'
import { useModal } from './modal'

export default defineComponent({
  setup() {
    const modal = useModal()

    return {
      showModal: modal.show(),
      visible: modal.visible
    }
  }
})
</script>
```

## A simple `useModal` hook

Let's start defining the hook. We will do this in a `vue` file - `Modal.vue`. Create a new component and add the following (there is a lot going on, I explain it directly underneath!)

```html
<template>

</template>

<script lang="ts">
import { defineComponent, ref } from "vue";

const show = ref(false)

export const useModal = () => {
  return {
    showModal() {
      show.value = true
    },
    hideModal() {
      show.value = false
    },
    visible() {
      show.value
    }
  }
}
</script>
```

`useModal` returns an object with two functions. Two are just a nice public interface to show and hide the modal - and the final just returns whether the modal is current visible or not.

This is far from an ideal implementation - we don't want `visible` to be writable, for example - it would be cleaner to make this a read only property, as opposed to a writable `ref`. We will fix this later using `Proxy`, the ES6 construct that Vue 3 is built on top of. For now, we will focus on getting everything working then refactor.

> Make it work, make it right, make it fast

## The Modal Template

You can use whatever markup and styling you like. I am using [Bulma](https://bulma.io/), a simple CSS only framework. The markup for my modal is like this:

```html
<template>
  <div class="modal" :style="style">
    <div class="modal-background"></div>
    <div class="modal-content">
      <div id="modal-dest"></div>
    </div>
    <button class="modal-close is-large" aria-label="close" @click="hide"></button>
  </div>
</template>
```

We haven't created the `style` binding in the first `<div>` or the `hide` function in the `<button>`. Add those to the `<script>` under the `useModal` function:

```ts
export default defineComponent({
  setup() {
    const modal = useModal()

    const style = computed(() => {
      return {
        display: show.value ? 'block' : 'none'
      }
    })

    return {
      style,
      hide: modal.hideModal,
    }
  }
})
```

The Bulma modal overlay defaults to `display: none` and you make it visible by setting `display: block`. We accomplish this by binding to `show.value`.

## The Modal Destination

You may have noticed the use of `<teleport to="#modal-dest">` right at the start - we need to create that destination now. This should be as high up the DOM tree as possible - we want the modal to overlay above everything else. We could ask the user to insert a `<div id="modal">` in their `index.html`, but it would be much cleaner if we could do it for them. Let's do that.

Let's say `index.html` looks like this:

```html
<html>
  <!-- ... --->
  <body>
    <div id="app"></div>
  </body>
  <!-- ... --->
</html>
```

We will insert the `<div id="modal">` between `<body>` and `<div id="app">`.

In a new file, `modal-plugin.ts`, add the following:

```ts
export class ModalPlugin {
  static install() {
    const el = document.createElement('div')
    el.id = 'modal'
    document.body.insertAdjacentElement('afterbegin', el)
    const app = createApp(ModalApp).mount('#modal')
  }
}
```

We are making a new `<div>` for the modal - which is actually *another* Vue app - to mount on. We use `insertAdjacentElement('afterbegin')` to mount the modal app in between `<body>` and `<div id="app">`. [`insertAdjacentElement`](https://developer.mozilla.org/en-US/docs/Web/API/Element/insertAdjacentElement) can insert different ways depending on the first argument, you can read more about it on MDN.

Finally, head to `main.ts` (or the root of your app) and use the `ModalPlugin`. Mine looks like this:

```ts
import { createApp } from 'vue'
import { ModalPlugin } from '../modal-plugin'

import App from './App.vue'

const app = createApp(App)
app.use(ModalPlugin)
app.mount('#app')
```

And this should be enough to get everything working!

## Improvements with Proxy

We can use a `Proxy` to only expose `visible` as a readonly property. This probably isn't perfect (I am still learning the in and outs of `Proxy` as well), but it will still accomplishes what we want. Basically, when using a `Proxy`, you define what happens using `get` and `set` - in this case, we will not implement `set` at all, so the user cannot update `visible` by `visible.value = false`.

We continue exposing `hideModal` and `showModal` as functions. The implementation is as follows:

```ts
interface ModalApi {
  hideModal: () => void
  showModal: () => void
  visible: boolean
}

export const useModal = (): ModalApi => {
  return new Proxy<ModalApi>(Object.create(null), {
    get(obj, prop) {
      if (prop === 'visible') {
        return computed(() => show.value)
      }
      if (prop === 'hideModal') {
        return () => show.value = false
      }
      if (prop === 'showModal') {
        return () => show.value = true
      }
    }
  })
}
```

A better implementation might be with `classes` and by using a `get` property on `visible` - however, I think this is a good opportunity to share a real use case for `Proxy`. A good exercise would be to rewrite this using a `class`. Something like:

```ts
class ModalApi {
  showModal() {
    // ...
  }

  hideModal() {
    // ...
  }

  get visible() {
    // ...
  }
}
```

## Other Improvements

At the moment we will show *all* the modals in the entire application if `visible` is `true`. To support different modals, an additional flag specifying which modal is required. For example:

```ts
modal.showModal({ id: 'signup' })
```

You could use a unique id, or even pass the actual Component, then render it using a dynamic component. This would work something like this:

```ts
modal.showModal({ component: Signup })

<template>
  <component :is="modal.component" />
</template>
```

There are many solutions - pick one that works best for your application.

Another improvement would be to use a constant for the `<teleport to"...">` and in the `<Modal>` component, since typing strings manually is error prone. For example:

```html
<template>
  <teleport :to="modalTarget">
</template>

<script lang="ts">
export default {
  setup() {
    const modal = useModal()

    return {
      modalTarget: modal.target // `modal.target could be '#destination' for example.
  }
}
</script>
```

## Conclusion

We build a `useModal` hook using `ref`, `computed` and a simple object in combination with `<teleport`>. We also explored how we can use `Proxy` for more fine-grained control over object access.
