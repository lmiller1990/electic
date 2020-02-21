Vue 3 is highly modular, exposing different packages for reactivity, rendering, and runtime. Let's explore the `runtime-dom` and `runtime-core` packages, published as part of Vue 3, and build a custom DOM renderer.

## Getting Started

In this article we will explore building a simple, custom renderer using Vue 3's new module runtime packages. Our renderer will still target the DOM, but with some extra features. You could target something else, like WebGL, Canvas, or iOS/Android if you were ambitious (this is was React Native does).

We are most interested in `@vue/runtime-core` and `@vue/runtime-dom`, publushed as part of the [`vue-next`](https://github.com/vuejs/vue-next/tree/master/packages) repository. We will build a custom renderer, and see what that process looks like. Finally, modify the renderer to stub out custom components, something Vue Test Utils features via the `stubs` mounting option and `shallowMount`. 

First, let's install the dependencies required: `yarn add typescript ts-node jsdom jsdom-global vue@3.0.0-alpha.5 pretty`.

I'm going to use a slightly modified version of `@vue/runtime-dom` for this article. Specifically, I want to export `nodeOps` and `patchProp`. I'll discuss what they do in more detail later in this article. You can see them imported in `runtime-dom` [here](yarn link "@vue/runtime-dom"). I pulled the `vue-next` repository, and installed the dependencies with `yarn install`. I changed in the `packages/runtime-dom` directory and I updated the `src/index.ts` file, so the bottom of the file now has these two lines:

```ts
export * from '@vue/runtime-core'
export {
  nodeOps,
  patchProp
}
```

Next I ran `yarn build runtime-dom runtime-core` to rebuild the package with the extra `export` statements.Lastly, I ran `yarn link`. I then changed into my custom renderer project directory. It only contains a `package.json` at this point. I ran `yarn link "@vue/runtime-dom"`, which was successful and displayed `success Using linked package for "@vue/runtime-dom"`.

## Our First Renderer

Now that is set up. Let's start off by importing some packages from Vue, and getting something rendering. I'll be using `render` functions instead of templates, just to save the time of configuring `vue-loader`.

```js
import 'jsdom-global/register'
import * as pretty from 'pretty'
import { createRenderer } from '@vue/runtime-core'
import {
  patchProp,
  h,
  nodeOps
} from '@vue/runtime-dom'

const { createApp } = createRenderer({
  ...nodeOps,
  patchProp
})

const el = document.createElement('div')
el.id = 'app'
document.body.appendChild(el)

const App = {
  render() {
     h('div', 'ok')
  }
}

createApp(App).mount(document.getElementById('app'))

console.log(pretty(document.body.outerHTML))
```

Running this prints:

```
<body>
  <div id="app">
    <div>ok</div>
  </div>
</body>
```

The first half of the code is by far the most interesting - let's look into it in a bit more depth.

```js
import { createRenderer } from '@vue/runtime-core'
import {
  patchProp,
  h,
  nodeOps
} from '@vue/runtime-dom'

const { createApp } = createRenderer({
  ...nodeOps,
  patchProp
})
```

`createRenderer` is the function Vue exposes to allow us to create custom renderers. It takes a single argument. `createRenderer` is defined in the Vue source code [here](https://github.com/vuejs/vue-next/blob/master/packages/runtime-core/src/renderer.ts). It takes an object with the following methods (I removed the arguments to keep things concise):

```ts
export interface RendererOptions<HostNode = any, HostElement = any> {
  patchProp(...): void
  insert(...): void
  remove(...): void
  createElement(...): HostElement
  createText(...): HostNode
  createComment(...): HostNode
  setText(...): void
  setElementText(...): void
  parentNode(...): HostElement | null
  nextSibling(...): HostNode | null
  querySelector?(...): HostElement | null
  setScopeId?(...): void
  cloneNode?(): HostNode
  insertStaticContent?(...): HostElement
}
```

Instead of defining our own, I'll be using the existing ones, imported via `nodeOps`, and extending a few to illustrate the concept. It's pretty clear from the name of each of the functions what they do - we basically have the classic CRUD actions, targeting the DOM:

CREATE: createElement, createText, createComment, cloneNode...
READ: querySelector
UPDATE: setText, setElementText, patchProp...
DELETE: remove

## Customize `insert`

Let's start by customizing `insert`. I basically grabbed the code from the `vue-next` source and modified it a bit. `insert` serves two purposes; if an `anchor` is provided, it will insert an element before the `anchor` element, otherwise it simply appends the child to the parent node. We also are making all our elements have a blue background.

```js
const { createApp } = createRenderer({
  ...nodeOps,
  patchProp,
  insert: (child, parent, anchor) => {
    child.style = "background-color: blue" 
    if (anchor != null) {
      parent.insertBefore(child, anchor)
    } else {
      parent.appendChild(child)
    }
  },
})
```

Running the code again shows this working:

```html
<body>
  <div id="app">
    <div style="background-color: blue;">ok</div>
  </div>
</body>
```

## Customizing `createText`

The `<div style="background-color: blue;">ok</div>` may be inserted by `insert`, but it also uses another method in the renderer; `createText`, to create the `ok` text. Let's modify `createText` to always append a `!` to the text. Note I wrapped the `ok` in `App` in an array, to force Vue to create a new text node instead of just setting `innerHTML`.

```js
const { createApp } = createRenderer({
  ...nodeOps,
  patchProp,
  createText: (text) => {
    return document.createTextNode(`${text}!`)
  },
  insert: (child, parent, anchor) => {
    child.style = "background-color: blue" 
    if (anchor != null) {
      parent.insertBefore(child, anchor)
    } else {
      parent.appendChild(child)
    }
  },
})

// ...

const App = {
  render() {
    return h('div', ['ok'])
  }
}
```

This gives us:

```html
<body>
  <div id="app">
    <div style="background-color: blue;">ok!</div>
  </div>
</body>
```

Great. Let's move on to something a more practical.

## Stub Renderer

Vue Test Utils has a feature that lets you `stub` out a component. This is useful if you have a component you don't want to render, because it does some API calls, or has some side effect you don't want in your tests. You can also use `shallowMount` to stub out all children.  We can't accomplish this in the any of the methods we pass to `createRenderer` though; by that point, Vue has compiled custom components, and we are just working with raw DOM elements. instead, let's modify the `h` function to support stubbing out components. `h` has a ton of different signatures, see the full implementation in `@vue/runtime-core` [here](https://github.com/vuejs/vue-next/blob/master/packages/runtime-core/src/h.ts).

We will import it by doing `import * as DOM fro '@vue/runtime-core`. If we just do `import { h } from '@vue-runtime/core`, we will not be able to override it. For now, let's just add some `console.log`.

```js
import * as DOM from '@vue/runtime-dom'
const originalH = DOM.h
DOM.h = (...args) => {
  console.log(args)
  return originalH(...args)
}
```

Running this, we get `[ 'div', [ 'ok' ] ]`. The first argument is the tag, the second is the children. Makes sense - we pass in `h('div', ['ok'])`. Let's add a custom component, and see what happens:

```js

const Hello = {
  mount() {
    console.log('Mount')
  },
  render() {
    return h('div', 'Custom Component')
  }
}

const App = {
  render() {
    return h('div', h(Hello))
  }
}
```

Running this gives us a whole bunch of stuff. The interesting part is `args[0]` for the custom component:

```js
[ { mount: [Function: mount], render: [Function: render] } ]
```

The first argument is the component itself - in our case, it's an object with `mount` and `render` functions. Let's say we wanted to stub out `Hello` - we can do a check here:

```js
import * as DOM from '@vue/runtime-dom'
const originalH = DOM.h
DOM.h = (...args) => {
  if (args[0] === Hello) {
    return originalH('stub')
  }
  return originalH(...args)
}
```

Now we get:

```html
<body>
  <div id="app">
    <div style="background-color: blue;">
      <stub style="background-color: blue;"></stub>
    </div>
  </div>
</body>
```

The stub still gets the `style`. This shows was I said earlier - the functions passed into `createRenderer` are run on the raw DOM elements, after the custom components have been compiled by Vue. Note that the `console.log` in `mount` no longer triggers - this is correct behavior for a stub, we should not be calling any of it's methods or lifecycle hooks.

We could improve the stub `h` function by checking if the component has a `name`, and rendering `${name}-stub`. Then we'd get:

```html
<body>
  <div id="app">
    <div style="background-color: blue;">
      <hello-stub style="background-color: blue;"></hello-stub>
    </div>
  </div>
</body>
```

Which looks a little nicer.

## Improvements

There are some improvements for this stub renderer - namely, we'd want to have an array of stubs that we check against, instead of hardcoding `args[0] === Hello` - it would be nice if the user could define their own custom stub render function, for example they might want to render something different, like a component designed specifically for testing or assertions. We also had to modify the Vue source to expose `nodeOps` - maybe there is a way to extend the DOM renderer without this.

## Conclusion

We've seen how you can build, or extend, a custom renderer with Vue's new modular structure. I'd like to look at a more robust custom renderer in the future, perhaps something relating to SVG or Canvas. Digging into a complex code base can be daunting, but experimenting is the best way to learn.
