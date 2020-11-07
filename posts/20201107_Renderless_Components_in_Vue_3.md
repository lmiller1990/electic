The "renderless components" pattern is something that has been around for a while, but hasn't gained (much) mainstream popularity. It's a really powerful abstraction to build re-useable components. 

The source code for this article is [available here](https://gist.github.com/lmiller1990/48c4fd841b67eaa4f226011f70351daf).

Let's see a simple example:

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/renderless/ss1.png)

In this image there are three inputs rendered. The markup and style is slightly different:

1. The first input has the validation below the input.
2. The second input has the validation to the right.
3. The third input has the validation to the left, and it's slightly smaller.

These may seem like tiny customizations, but many UI frameworks make it very difficult to move things around like this! The idea of a renderless component is it has *no opinion on how things look*. In the above example, the renderless component exposes validation, but no specific markup - the developer can decide where and how things are rendered, without needing to re-implement validation.

There are many benefits to this approach. Every tried to use an input (eg `vue-multiselect`) and had to hack the styling to pieces to get it to fit in with your application's theme? Or do something dirty to get Vuetify to look how you want? Yeah, me too. This is the problem renderless components solves. A great pattern for a component you are thinking about publishing on npm.

## Getting Started

In this example we will work with two components: `app.vue`, which is where the developer is using the input, and `v-input.vue`, which is the renderless component. This is something you could be importing from a library, or installing from npm. This means:

- `app` is the specific to your application
- `v-input` is not. It should be re-usable and unopinionated.

Start with `app.vue`:

```html
<template>
  <v-input>
    Hello
  </v-input>
</template>

<script>
import VInput from './v-input.vue'

export default {
  components: { VInput }
}
</script>
```

And a minimal `v-input.vue`:

```html
<script>
export default {
  setup(props, ctx) {
    return () => ctx.slots.default()
  }
}
</script>
```

Notice there is

- no render function with `h`
- no `<template>`

That's because it's *renderless*. The trick is `return () => ctx.slots.default()`. This will evaluate to the "Hello" text node we passed in `<app>`.

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/renderless/ss2.png)

Let's render something a bit more useful - starting with an `<input>`.

```html
<template>
  <v-input >
    <input v-model="username" />
  </v-input>
</template>

<script>
import { ref } from 'vue'
import VInput from './v-input.vue'

export default {
  components: { VInput },
  setup() {
    return {
      username: ref('')
    }
  }
}
</script>
```

Stll no need to update `<v-input`>:

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/renderless/ss3.png)

## Child -> Parent Communication

Now to add the validation logic. We want a `min` and `max` length, so we will need to pass those to the `<v-input>`. We also need to pass the `username` to be validated. No problem here - we can use `props`. 

What we also need to do is validate the username in `<v-input>` and pass any validation errors *back to the parent* - that is to say, child -> parent communication. One way to do this is `emit` - but there is a more idiomatic way for renderless components, `v-slot`.

Update `app.vue` to pass the relevant props. I am also destructuring on `v-slot` and grabbing an `error` property. More on that soon.

```html
<template>
  <v-input >
  <v-input 
    v-slot="{ error }"
    :min="5"
    :max="10"
    :value="username"
  >
    <input v-model="username" />
    <div v-if="error" class="error">
      {{ error }}
    </div>
  </v-input>
</template>

<script>
import { ref } from 'vue'
import VInput from './v-input.vue'

export default {
  components: { VInput },
  setup() {
    return {
      username: ref('')
    }
  }
}
</script>
```

Here comes some more renderless comoponent magic. Update `v-input.vue`:

```html
<script>
function getError(value, { min, max }) {
  if (!value) {
    return 'Required'
  }

  if (value.length < min) {
    return `Min is ${min}`
  }

  if (value.length > max) {
    return `Max is ${max}`
  }
}

import { computed } from 'vue'

export default {
  props: ['min', 'max', 'value'],
  setup(props, ctx) {
    const error = computed(() => getError(
      props.value,
      { min: props.min, max: props.max }
    ))

    return () => ctx.slots.default({
      error: error.value
    })
  }
}
</script>
```

This is cool. We can pass computed and reactive values from the default slot back to the parent by passing an object into `ctx.slots.default()`. That is then available via destructuring and `v-slot`.

I added some styling - it works! I tried making another version by moving the markup around, too. Now the developer is free to manipulate the markup however they like, and take full advantage of the re-usable business logic in the renderless `<v-input>` component.

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/renderless/ss4.png)

## A More Complex Example

I expanded this idea and make a renderless password complexity component. 

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/renderless/ss5.png)

You can grab the full source and tutorial in my upcoming book, [Design Patterns for Vue.js: A test driven approach to maintainable applications](https://lachlan-miller.me/design-patterns-for-vuejs).

The source code for this article is [available here](https://gist.github.com/lmiller1990/48c4fd841b67eaa4f226011f70351daf).
