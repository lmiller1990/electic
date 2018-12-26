In this article, I will talk about how I have been using Vue, and plan to do so in 2019. The main new technologies I've found useful over the last year have been TypeScript and `.tsx` instead of `.vue` files. 

The main benefit of using `.tsx` over `.vue` files is typechecking in the `render` function - as far as I know, `.vue` files to not have typechecking in the `<template>` section, or at least it is not very well supported.

The app we are building will look like this:

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/vue_tsx/ss.png)

The source code for this article is available [here](https://github.com/lmiller1990/vue_tsx_article_demo).

You can select a sign, and it will perform the calculation.

## Setup

Install the Vue CLI v3 if you haven't already, then create a new app by running `vue create tsx_adder`. 

For each of prompts

- The only feature we want is TypeScript and Babel, so select those two. 
- We do not want the class-style component syntax
- We do want Babel
- select "in dedicated files" for the config

Once that has finished installing, `cd tsx_adder`. We need one dependency to be able to use TSX. That is `vue-tsx-support`. Install in by running `vue add tsx-support`. We will also demonstrate Vuex with TypeScript, so add it with `yarn add vuex`.

## Structure

The application will have two components: `App.tsx` and `Adder.tsx`. The `App.tsx` will connect to the Vuex store and pass props to the `Adder`, which is the presentation component that will handle the layout and UI. As per the container/presenter pattern (also known as smart/dumb, container/component), In a large app, you would probably have an `AdderContainer.tsx`, but for simplicity I am just using `App.tsx` to interface with the store. `Adder.tsx` receives data from the store via props, and communicates with the parent by emitting events. This will let us demonstrate:

- typesafe props, including complex types like Enums and Objects
- typechecked events between the parent/child component
- how to get type inference and type safety with Vuex State in components

Start off by converting `App.vue` to `App.tsx`. Update it to contain the following:

```ts
import * as tsx from 'vue-tsx-support'
import { VNode } from 'vue'

const App = tsx.component({
  name: 'App',

  render(): VNode {
    return (
      <Adder />
    )
  }
})

export { App }
```

Since we haven't created `Adder.tsx` yet, create it: `components/Adder.tsx`. Inside `components/Adder.tsx`, add the following bare-bones component:

```ts
import * as tsx from 'vue-tsx-support'
import { VNode } from 'vue'

const Adder = tsx.component({
  name: 'Adder',

  render(): VNode {
    return (
      <div>Adder</div>
    )
  }
})

export { Adder }
```

Now import it in `App.tsx`: `import { Adder } from './components/Adder'`. Lastly, head to `main.ts` and change `import App from './App.vue` to `import { App } from './App'`. Run `yarn serve` (or `npm run serve`). `localhost:8080` should show the following:

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/vue_tsx/basic.png)

## Typesafe Props

The first thing we will demonstrate is typesafe props, including both primitives (like `Number` and `Boolean`) as well as complex types, like `Enum`. In `Adder.tsx`, add the following:

```ts
props: {
  left: {
    type: Number,
    required: true as true
  },

  right: {
    type: Number,
    required: true as true
  }
},
```

One caveat is you need to type `true as true` to get TypeScript to check the props at compile time. It is discussed breifly [here](https://github.com/wonderful-panda/vue-tsx-support#available-apis-to-add-type-information). One you add that, if your editor supports TypeScript (for example VS Code), head back to `App.tsx`, and you should see an error, and `<Adder >` has a red line under it. Towards the end of the error message, it says `Type '{}' is missing the following properties from type '{ left: number; right: number; }': left, right`. Let's provide `left` and `right` in `App.tsx`:

```ts
render(): VNode {
  return (
    <Adder 
      left={5}
      right={3}
    />
  )
}
```

Try passing a string instead - TypeScript will warn us the prop type is incorrect.

Next, let's add a more complex type - an `enum`. Create a directory called `types` under `src`, and inside it a `sign.ts` file with the following:

```ts
enum Sign {
  'x' = 'x',
  '/' = '/',
  '+' = '+',
  '-' = '-'
}

export { Sign }
```

Next update `Adder.tsx`:

```ts
import { Sign } from '@/types/sign'

// ...

props: {
  selectedSign: {
    type: String as () => Sign,
    required: true as true
  }
}
```


Another unforunately hack, which shows some of the limits of Vue's TS support is `String as () => Sign`. Since our `Sign` enum is just Strings, we do `String as () => ...`. If it was an enum of `Object` or `Array`, we would type `Array as () => MyComplexArrayType[]`. More information about this is found [here](https://frontendsociety.com/using-a-typescript-interfaces-and-types-as-a-prop-type-in-vuejs-508ab3f83480).

Head back to `App.tsx`, and you'll see another error around `<Adder />`. Fix it by adding the following:

```ts
// ...
import { Sign } from '@/types/sign'

// ...

  render(): VNode {
    return (
      <Adder 
        left={5}
        right={3}
        selectedSign={Sign['+']}
      />
    )
  }
```

## Typesafe Events

Now let's see how to have typechecked events. We want the adder to emit a `changeSign` event when any of the four signs are clicked. This can be achieved using `componentFactoryOf`, documented [here](https://github.com/wonderful-panda/vue-tsx-support#componentfactoryof). Start by updating `App.tsx`:

```ts
// imports...
const App = tsx.component({
  name: 'App',

  methods: {
    changeSign(sign: Sign) {

    }
  },

  render(): VNode {
    return (
      <Adder 
        left={5}
        right={3}
        selectedSign={Sign['+']}
        onChangeSign={this.changeSign}
      />
    )
  }
})

export { App }
```

`<Adder />` has an error again: `Property 'onChangeSign' does not exist on type '({ props: ...`. That's because we are passing a prop that `Adder` doesn't expect.

Add the following to `Adder.tsx`:

```ts
interface IEvents {
  onChangeSign: (sign: Sign) => void
}

const Adder = tsx.componentFactoryOf<IEvents>().create({

  // ...
})
```

Now the error is gone. Try changing the signature of `changeSign(sign: Sign)` to `changeSign(sign: Number)` - TS warns you the parameter has the  incorrect type, very cool. Read more about `componentFactoryOf` [here](https://github.com/wonderful-panda/vue-tsx-support#componentfactoryof).

Two last things to complete the `Adder.tsx` component. First, add the following interface at the top, and `data` function:

```ts
// imports ...
interface IAdderData {
  signs: Sign[]
}

const Adder = tsx.componentFactoryOf<IEvents>().create({
  // ...
  
  data(): IAdderData {
    return {
      signs: [
        Sign["+"],
        Sign["-"],
        Sign["x"],
        Sign["/"]
      ]
    }
  }
```

Lastly, let's add the `render` function for `Adder.tsx`. It isn't anything special, so I won't go into detail.

```ts
render(): VNode {
  const { signs, left, right, selectedSign } = this

  return (
    <div class='wrapper'>
      <div class='inner'>
        <div class='number'>
          {left}
        </div>

        <div class='signs'>
          {signs.map(sign =>
            <span 
              class={sign === selectedSign ? 'selected sign' : 'sign'}
              onClick={() => this.$emit('changeSign', sign)}
            >
              {sign}
            </span>)
          }
        </div>

        <div class='number'>
          {right}
        </div>
      </div>

      <div class='result'>
        <span>
          Result: {this.$slots.result}
        </span>
      </div>
    </div>
  )
}
```

One small caveat is we define the event interface as `onChangeSign`, but we emit `changeSign`.

To make the app look a bit better, here is some css. Create `components/adder.css` and insert to following:

```css
.wrapper, .signs {
  display: flex;
  flex-direction: column;
  width: 200px;
}

.signs {
  align-items: center;
}

.sign {
  cursor: pointer;
  border: 2px solid rgba(100, 100, 20, 0.4);
  padding: 5px;
  width: 30px;
  height: 30px;
  margin: 5px;
  display: flex;
  justify-content: center;
  align-items: center;
}

.selected {
  background-color: rgba(0, 0, 255, 0.4);
}

.inner {
  display: flex;
  justify-content: space-between;
}

.number {
  font-size: 2.5em;
}

.result {
  font-size: 3em;
}
```

Then do `import './adder.css'` at the top of `Adder.tsx`. The page now looks like this:

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/vue_tsx/ss_2.png)

Let's add Vuex and make the buttons work now.

## Adding a Typesafe Vuex store

The next step for the app is adding a (somewhat) typsafe Vuex store. Make a `store` folder inside of `src`, then inside of `store` create `index.ts` and `calculation.ts`. Inside `store/index.ts`, add the following:

```ts
import Vue from 'vue'
import Vuex from 'vuex'

import { calculation, ICalculationState } from './calculation'

Vue.use(Vuex)

interface IState {
  calculation: ICalculationState
}

const store = new Vuex.Store<IState>({
  modules: {
    calculation
  }
})

export { store, IState } 
```

Nothing especially exciting - we just define a new Veux store, and pass a `calculation` module, which we are going to make now. In `calculation.ts` add the following:

```ts
import { Module } from 'vuex'

interface ICalculationState {
  left: number
  right: number
}

const calculation: Module<ICalculationState, {}> = {
  state: {
    left: 3,
    right: 1
  }
}

export {
  calculation,
  ICalculationState
}
```

We define a `calculation` module, with the `left` and `right` values in the state. Import it in `main.ts`:

```ts
import Vue from 'vue'
import { App } from './App'
import { store } from '@/store'

Vue.config.productionTip = false

new Vue({
  store,
  render: h => h(App)
}).$mount('#app')
```

Let's use these values in the app now. Update `App.tsx`:

```ts
import * as tsx from 'vue-tsx-support'
import { VNode } from 'vue'
import { Adder } from './components/Adder'

import { Sign } from '@/types/sign'
import { IState } from '@/store'

const App = tsx.component({
  name: 'App',

  computed: {
    left(): number {
      return (this.$store.state as IState).calculation.left
    },

    right(): number {
      return (this.$store.state as IState).calculation.right
    }
  },

  methods: {
    changeSign(sign: Sign) {

    }
  },

  render(): VNode {
    return (
      <Adder 
        left={this.left}
        right={this.right}
        selectedSign={Sign['+']}
        onChangeSign={this.changeSign}
      />
    )
  }
})

export { App }
```

We need to type `(this.$store.state as IState)` to get typechecking on the store modules. There are other alternatives that will let you get type checking without casting `this.$state` to `IState`, but I've been using this pattern and found it pretty good so far.

## Adding a Mutation

Let's add a mutation. The goal will be to save the `selectedSign` in the state, and update it with a mutation. Update `calculation.ts`:

```ts
import { Module } from 'vuex'

import { Sign } from '@/types/sign'

interface ICalculationState {
  left: number
  right: number
  sign: Sign
}

const SET_SIGN = 'SET_SIGN'

const calculation: Module<ICalculationState, {}> = {
  namespaced: true,

  state: {
    left: 3,
    right: 1,
    sign: Sign['+']
  },

  mutations: {
    [SET_SIGN](state, payload: Sign) {
      state.sign = payload
    }
  }
}

export {
  calculation,
  ICalculationState
}
```

We added a `SET_SIGN` mutation. The type of `state` is interferred, since we passed in `ICalculationState` to `Module` when we declared the calculation module. We can use the new mutation in `App.tsx`:

```ts
// ...
  methods: {
    changeSign(sign: Sign) {
      this.$store.commit('calculation/SET_SIGN', sign)
    }
  },
// ...
```

We do not get any typechecking on the `commit` handler or payload. This is still a problem I'm exploring solutions to. There are a few solutions out there, but none of which feel clean enough, or require a level of abstraction I'm not happy with. I hope Vuex itself can evolve to provide a better TS experience out of the box in the future. I will propose my solution in a follow up article.

Let's finish the app off. Update `App.tsx` with the final code, which includes a computer property, `result`, to calculate the value based on the sign:

```ts
import * as tsx from 'vue-tsx-support'
import { VNode } from 'vue'
import { Adder } from './components/Adder'

import { Sign } from '@/types/sign'
import { IState } from '@/store'

const App = tsx.component({
  name: 'App',

  computed: {
    left(): number {
      return (this.$store.state as IState).calculation.left
    },

    right(): number {
      return (this.$store.state as IState).calculation.right
    },

    sign(): Sign {
      return (this.$store.state as IState).calculation.sign
    },

    result(): number {
      switch (this.sign) {
        case Sign['+']:
          return this.left + this.right
        case Sign['-']:
          return this.left - this.right
        case Sign['x']:
          return this.left * this.right
        case Sign['/']:
          return this.left / this.right
      }
    }
  },

  methods: {
    changeSign(sign: Sign) {
      this.$store.commit('calculation/SET_SIGN', sign)
    }
  },

  render(): VNode {
    return (
      <Adder 
        left={this.left}
        right={this.right}
        selectedSign={this.sign}
        onChangeSign={this.changeSign}
      >
        <div slot='result'>
          {this.result}
        </div>
      </Adder>
    )
  }
})

export { App }
```

Now the app looks like this:

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/vue_tsx/ss.png)

Clicking the signs updates the `result` based on the calculation.

## Improvements and Conclusion

This article demonstrates:

- creating Vue components using `tsx`
- Typesafe props and events
- Typesafety for `this.$store` by using an interface

Some improvements I'd like to cover in a future article include:

- Typesafe getters, commit(mutation) and dispatch(action)

The source code for this article is available [here](https://github.com/lmiller1990/vue_tsx_article_demo). Originally published on [my personal blog](https://lmiller1990.github.io/electic/).
