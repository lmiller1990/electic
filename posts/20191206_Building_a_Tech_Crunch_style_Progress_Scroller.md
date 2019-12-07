In this article, I'll look at how you can replicate the circular progress scroller [Tech Crunch](https://techcrunch.com/) use to gamify their articles, encouraging users to scroll to the end (and view the advertisement on the end of the article). 

This will be build using Vue, TypeScript and SVG. We will be separating the business logic (calculations related to scrolling and animation) from Vue entirely, though, so you could easily adapt this to your framework of choice. 

The source code is available [here](https://github.com/lmiller1990/vue-scroll-progress) and a working demo [here](https://lmiller1990.github.io/vue-scroll-progress/).

This article isn't a typical "here's the code, copy and paste it" guide - I'll write a basic proof of concept first, and then refactor it, discussing some best practices I've learned building Vue apps and framework agnostic libraries over the years. Specifically, I'll look at separating framework-agnostic logic (eg, business logic that doesn't use any of Vue's APIs) from framework specific code (eg, the parts of the app that reference `this`, referring to the Vue instance, or make use Vue's reactivity system, such as computed properties).

There is a lot of value in correctly separating the concerns; it allows you to easily integrate generic libraries to your framework of choice, makes unit testing easier, and keeps your components simple - Vue is a framework for building UIs, so most of the code in your components should be related to presenting data, not business logic.

I'll start of by making a new Vue app using the `vue-cli` with the following options: TyepeScript, Babel, no class component syntax.

First, I'll create a component called `Progress.vue` in `src/components`. Inside, add the following minimal code - the explanation follows.

```vue
<template>
  <div>
    {{ percent }}
  </div>
</template>

<script lang="ts">
import Vue from 'vue'

interface IMarkers {
  progressStartMarker: HTMLElement | null
  progressEndMarker: HTMLElement | null
}

interface IData extends IMarkers {
  percent: number
  scrollEvent: ((this: Window, ev: Event) => void) | null
}

export default Vue.extend({
  name: 'Progress',  
  
  data(): IData {
    return {
      percent: 0,
      scrollEvent: null,
      progressStartMarker: null,
      progressEndMarker: null,
    }
  }
})
</script>

<style scoped>
div {
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid red;
  height: 50px;
  width: 50px;
  position: fixed;
  right: 25px;
}
</style>
```

The way this is going to work is the user will specify two _markers_. They start of as `null`. These indicate which two points we want to track scroll progress between. For now, they will just be HTML elements selected by `document.querySelector`, but you could allow the user to pass these as props as well. We will store the user's scroll percentage in the `data` object.

Now, add the following code to `App.vue`, which we will use to test the `<Progress />` component.

```vue
<template>
  <div id="app">

    <Progress />

    <div
      v-for="item in items.slice(0, 10)"
      :key="item"
      class="item"
    >
      {{ item }}
    </div>

    <div id="progress-marker-start"></div>

    <div
      v-for="item in items.slice(10, 80)"
      :key="item"
      class="item"
    >
      {{ item }}
    </div>

    <div id="progress-marker-end"></div>

    <div
      v-for="item in items.slice(80)"
      :key="item"
      class="item"
    >
      {{ item }}
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'

import Progress from './components/Progress.vue'

interface IData {
  items: string[]
}

export default Vue.extend({
  name: 'app',

  components: {
    Progress,
  },

  data(): IData {
    return {
      items: [],
    }
  },

  created() {
    for (let i = 0; i < 100; i++) {
      this.items.push(`Item ${i}`)
    }
  },
})
</script>

<style>
#app {
  margin: 25px;
}

#progress-marker-start, #progress-marker-end {
  border: 1px solid;
}

.item {
  margin: 5px;
  padding: 5px;
}
</style>
```

A lot of boilerplate, but nothing very exciting yet. We render a bunch of `<div />`. Then `<div id="progress-marker-start"></div>` - this is the point we will start tracking the scroll progress. Next we have some more `<div />`, and the end point, `<div id="progress-marker-end"></div>`. 

This renders the following:

![](https://raw.githubusercontent.com/lmiller1990/vue-scroll-progress/master/images/ss1.png) 

For the proof of concept, we will simply display a % in the top right corner as the user scrolls. 

## Calculating the Marker Offsets

There are a few strategies to calculate how far a user has scrolled. The one I have found to cover all the edge cases and work correctly requires three pieces of information to calculate:

1. The current position the users has scrolled to
2. The y position of `progress-marker-start`, relative to the top of the viewport
3. The y position of `progress-marker-end`, relative to the top of the viewport

Getting the current scroll position is trivial - we can use `window.scrollY` and call it a day. The other two y positions are a bit more tricky. A part of any algorithm to calculate the position of a HTML element will almost always include `getBoundingClientRect()`. My strategy is no different. At first, my strategy was to calculate the positions as follows:

```js
// start marker
Math.abs(document.body.getBoundingClientRect().top - startMarker.getBoundingClientRect().top)

// end marker
Math.abs(document.body.getBoundingClientRect().top - endMarker.getBoundingClientRect().top)
```

This seemed fine, until you add some padding to the `<div id="app" />` element - then `document.body.getBoundingClientRect().top` ceases to accurately reflect the top of the document! The following image illustrates this:

![](https://raw.githubusercontent.com/lmiller1990/vue-scroll-progress/master/images/ss2.png) 

You can see 25px are not accounted for, indicated by the red arrow. The way I solved this was using `document.documentElement.getBoundingClientRect().top`. `document.documentElement` refers the `<html />` element, and `getBoundingClientRect().top` returns 0:

![](https://raw.githubusercontent.com/lmiller1990/vue-scroll-progress/master/images/ss3.png) 

This is working great for me so far, but it's possible there are caveats to this method too (eg, if someone decided to add `margin` to the HTML, which is not something I've seen very often, if ever).

With this knowledge, we can add a cute little method that will get the y offset for an element. Add a `methods` key with the following function in `Progress.vue`:

```ts
methods: {
  getPosRelativeToBody(el: HTMLElement): number {
    return Math.abs(
      document.documentElement.getBoundingClientRect().top - el.getBoundingClientRect().top
    );
  },
}
```

## Calculating the Scroll Progress

I want to start counting scroll percentage not when the `<div id="progress-marker-start"></div>` appears on screen, but when it disappears above the top of the viewport. So all we need do is taken the different in the y position of the `<div id="progress-marker-start"></div>` and `<div id="progress-marker-end"></div>` and subtract `window.innerHeight`. This will give us the total pixels we want to track the scroll progress over.

```ts
const offsetFromTop = getPosRelativeToBody(startMarker)
const total = getPosRelativeToBody(endMarker) - offsetFromTop - window.innerHeight
```

Using the `App.vue` I defined, this works out to around 2011px.

Finally, we can calculate the percentage progress by dividing the `window.scrollY - offsetFromTop` by the total. `window.scrollY - offsetFromTop` reflects the point when the start marker is above the top of the current viewport.

```ts
const offsetFromTop = getPosRelativeToBody(startMarker)
const total = getPosRelativeToBody(endMarker) - offsetFromTop - window.innerHeight

// get the progress as a percentage
const progress = (((window.scrollY - offsetFromTop) / total) * 100)
```

Putting this all together, we get the following function. Add it to `Progress.vue` under `methods`:

```ts
methods: {
  // ...

  getScrollPercentage(startMarker: HTMLElement, endMarker: HTMLElement): void {
    const offsetFromTop = this.getPosRelativeToBody(startMarker)
    const total = this.getPosRelativeToBody(endMarker) - offsetFromTop - window.innerHeight
    const progress = (((window.scrollY - offsetFromTop) / total) * 100)
    this.percent = progress
  }

  // ...
}
```

The last thing to do is to call this method when the user scrolls. This isn't the final code - there are many improvements we will make - but the easiest way to test this is to add the event listener in a `mounted` hook in `Progress.vue`:

```ts
mounted() {
  this.progressStartMarker = document.querySelector<HTMLElement>('#progress-marker-start')
  this.progressEndMarker = document.querySelector<HTMLElement>('#progress-marker-end')

  if (!this.progressStartMarker || !this.progressEndMarker) {
    throw Error('Progress markers not found')
  }

  window.addEventListener('scroll', () => {
    this.getScrollPercentage(this.progressStartMarker!, this.progressEndMarker!)
  })
}
```

![](https://raw.githubusercontent.com/lmiller1990/vue-scroll-progress/master/images/ss3.5.png) 

It works! There are tons of improvements we will make, but this is a great proof of concept.

The entire `<script>` tag of `Progress.vue` so far is as follows:


```ts
import Vue from 'vue'

interface IMarkers {
  progressStartMarker: HTMLElement | null
  progressEndMarker: HTMLElement | null
}

interface IData extends IMarkers {
  percent: number
  scrollEvent: ((this: Window, ev: Event) => void) | null
}

export default Vue.extend({
  name: 'Progress',  
  
  data(): IData {
    return {
      percent: 0,
      scrollEvent: null,
      progressStartMarker: null,
      progressEndMarker: null,
    }
  },

  mounted() {
    this.progressStartMarker = document.querySelector<HTMLElement>('#progress-marker-start')
    this.progressEndMarker = document.querySelector<HTMLElement>('#progress-marker-end')

    if (!this.progressStartMarker || !this.progressEndMarker) {
      throw Error('Progress markers not found')
    }

    window.addEventListener('scroll', () => {
      this.getScrollPercentage(this.progressStartMarker!, this.progressEndMarker!)
    })
  },

  methods: {
    getScrollPercentage(startMarker: HTMLElement, endMarker: HTMLElement): void {
      const offsetFromTop = this.getPosRelativeToBody(startMarker)
      const total = this.getPosRelativeToBody(endMarker) - offsetFromTop - window.innerHeight
      const progress = (((window.scrollY - offsetFromTop) / total) * 100)
      this.percent = progress
    },

    getPosRelativeToBody(el: HTMLElement): number {
      return Math.abs(
        document.documentElement.getBoundingClientRect().top - el.getBoundingClientRect().top,
      );
    },
  }
})
```

## Extract the Logic out of the Component

Before we add a nice UI like Tech Crunch has, we can decouple the scroll logic from the component. Currently, if someone wants to use our scroll progress component, they need to pull in all of Vue - not ideal, if you site is not already using Vue. None of the logic we have written even uses any of Vue's API. 

Let's extract the logic, and make `<Progress />` a thin Vue wrapper connecting Vue and around the actual business logic. This gives us the option of releasing a framework-agonistic scroll progress library, which authors can then integrate to their Vue/React/Angular/whatever app. 

I'll create a `progress.ts` script in the `components` directory, and add the functions discussed above, making slight changes to their signatures:

```ts
const getScrollPercentage = (startMarker: HTMLElement, endMarker: HTMLElement): number => {
  const offsetFromTop = getPosRelativeToBody(startMarker)
  const total = getPosRelativeToBody(endMarker) - offsetFromTop - window.innerHeight
  const progress = (((window.scrollY - offsetFromTop) / total) * 100)
  return progress
}

const getPosRelativeToBody = (el: HTMLElement): number => {
  return Math.abs(
    document.documentElement.getBoundingClientRect().top - el.getBoundingClientRect().top,
  );
}

export {
  getScrollPercentage
}
```

Update `Progress.vue`. The `<script>` section of `<Progress />` is now just a thin wrapper around the logic in `progress.ts`:

```ts
import Vue from 'vue'

import { getScrollPercentage } from './progress'

interface IData {
  percent: number
  scrollEvent: ((this: Window, ev: Event) => void) | null
}

export default Vue.extend({
  name: 'Progress',  
  
  data(): IData {
    return {
      percent: 0,
      scrollEvent: null,
    }
  },

  mounted() {
    const progressStartMarker = document.querySelector<HTMLElement>('#progress-marker-start')
    const progressEndMarker = document.querySelector<HTMLElement>('#progress-marker-end')

    if (!progressStartMarker || !progressEndMarker) {
      throw Error('Progress markers not found')
    }

    window.addEventListener('scroll', () => {
      this.percent = getScrollPercentage(progressStartMarker, progressEndMarker)
    })
  }
})
```

Everything is still working! Let's add a circle UI that fills out as the users scrolls, like the one on Tech Crunch.

## Some SVG

Turns out you cannot make a incrementally filling circle like the one we want with CSS alone. Or, at least, it's not the best tool for the job. That honor goes to SVG. Before integrating the SVG circle animation into the app, we need to understand a bit about SVG.

A basic SVG circle is drawn as follows:

```html
<svg
   class="progress"
   width="120"
   height="120"
>
  <circle
    stroke-width="4"
    stroke="red"
    r="50"
    cx="60"
    cy="60"
    fill="transparent"
  />
</svg>
```

This appears like this:

![](https://raw.githubusercontent.com/lmiller1990/vue-scroll-progress/master/images/ss4.png) 

The next property we are interested in is `stroke-dasharray`. You can read more about this one MDN, however the basic premise is you can draw the shape with dashes, instead of a solid border. Here are some examples:

![](https://raw.githubusercontent.com/lmiller1990/vue-scroll-progress/master/images/ss5.png) 

For our purpose, we want `stroke-dasharray` to equal the circumference of our circle. We can calculate this programmatically: 2 * Math.PI * radius (which we specified to be 50px). This works out to be 314px for our circle. The following snippets demonstrates this calculation:

```html
<script>
document.addEventListener('DOMContentLoaded', () => {
  const circle = document.querySelector('circle')
  circle.style.strokeDasharray = circle.r.baseVal.value * Math.PI * 2
})
</script>

<svg
  class="progress"
  width="120"
  height="120"
>
  <circle
    stroke-width="4"
    stroke="red"
    r="50"
    cx="60"
    cy="60"
    fill="transparent"
  />
</svg>
```

Nothing looks different yet - still a red circle. However, now we can take advantage of another property, `stroke-dashoffset`. This sets the offset (from where the dash is drawn). Currently our circle is comprised of a single large dash, set using `stroke-dasharray`, that is the full circumference of the circle. Let's try some different numbers for `stroke-dasharray` and see how things change:

![](https://raw.githubusercontent.com/lmiller1990/vue-scroll-progress/master/images/ss6.png) 

As the stroke-dashoffset gets larger, the red circle is smaller! As it increases in size, the red border is almost entirely gone. So when the user has scrolled 0% of the area we are measuring, we want the `stroke-dashoffset` to be (circumference * progress), where progress is between 0 and 1. For example:

![](https://raw.githubusercontent.com/lmiller1990/vue-scroll-progress/master/images/ss7.png) 

Close, but not quite. This offsets the circle by 25%, drawing the remaining 75%. We actually want the other way around - only to draw 25%. So our calculation becomes (circumference - (circumference * progress)):

![](https://raw.githubusercontent.com/lmiller1990/vue-scroll-progress/master/images/ss8.png) 

Looks good!

## Integrating the SVG Circle and with Logic

Now we can have all the pieces need to draw circle as we scroll: the percentage change, and an SVG we can update with JavaScript. Let's do it. Update the `<template>` section of `Progress.vue`

```html
<template>
  <svg
    class="progress"
    width="120"
    height="120"
  >
    <circle
      stroke-width="0"
      stroke="red"
      r="50"
      cx="60"
      cy="60"
      fill="transparent"
    />
  </svg>
</template>
```

Next, update the `<style>` tag. It is a lot more simple now - we do most of the styling in the SVG now.

```html
<style scoped>
svg {
  position: fixed;
  right: 25px;
}
</style>
```

Next, we have an update to `progress.ts`. I added an `updateCircle` function, which implements the calculation discussed above, and cover a few edge cases. I also made some small changes to `getScrollPercentage`. The now completed `progress.ts` file looks like this:

```ts
const getScrollPercentage = (startMarker: HTMLElement, endMarker: HTMLElement): number => {
  const offsetFromTop = getPosRelativeToBody(startMarker)
  const total = getPosRelativeToBody(endMarker) - offsetFromTop - window.innerHeight
  const progress = ((window.scrollY - offsetFromTop) / total)
  return progress
}

const updateCircle = (circle: SVGCircleElement, progress: number): void => {
  const circumference = circle.r.baseVal.value * 2 * Math.PI

  // draw nothing
  if (progress < 0) {
    circle.style.strokeDashoffset = `${circumference}`
    return
  }

  // draw the full circle
  if (progress > 1) {
    circle.style.strokeDashoffset = '0'
    return
  }

  circle.style.strokeWidth = '4'
  circle.style.strokeDasharray = `${circumference}`
  const offset = circumference - (circumference * progress)
  circle.style.strokeDashoffset = `${offset}`
}

const getPosRelativeToBody = (el: HTMLElement): number => {
  return Math.abs(
    document.documentElement.getBoundingClientRect().top - el.getBoundingClientRect().top,
  );
}

export {
  getScrollPercentage,
  updateCircle,
}
```

Lastly, let's use the `updateCircle` function. Update the `<script>` section of `Progress.vue`:

```html
<script lang="ts">
import Vue from 'vue'

import { getScrollPercentage, updateCircle } from './progress'

interface IData {
  percent: number
  scrollEvent: ((this: Window, ev: Event) => void) | null
}

export default Vue.extend({
  name: 'Progress',  
  
  data(): IData {
    return {
      percent: 0,
      scrollEvent: null,
    }
  },

  mounted() {
    const circle = this.$el.querySelector<SVGCircleElement>("circle")
    const progressStartMarker = document.querySelector<HTMLElement>('#progress-marker-start')
    const progressEndMarker = document.querySelector<HTMLElement>('#progress-marker-end')

    if (!progressStartMarker || !progressEndMarker || !circle) {
      throw Error('Progress markers not found')
    }

    window.addEventListener('scroll', () => {
      const percent = getScrollPercentage(progressStartMarker, progressEndMarker)
      updateCircle(circle, percent)
    })
  },

  destroyed() {
    if (!this.scrollEvent) {
      return
    }

    window.removeEventListener('scroll', this.scrollEvent)
  },
})
</script>
```

I added a call to `updateCircle` in the `scroll` event listener's callback. I also remove the event listener on `destroyed` to avoid a potential memory leak.

## One Last Improvement - requestAnimationFrame

We can add one last mini improvement - only call `getScrollPercentage` and `updateCircle` when the browser redraws the screen, using `requestAnimationFrame`. Update the code in `mounted`:

```ts
window.addEventListener('scroll', () => {
  requestAnimationFrame(() => {
    const percent = getScrollPercentage(progressStartMarker, progressEndMarker)
    updateCircle(circle, percent)
  })
})
```

To learn why this is a good to do, research `requestAnimationFrame` and passive event listeners - there is a lot of information out there. There are other improvements and optimizations that I might write about in a future article.

## Conclusion

This article covered:

- some caveats of `getClientBoundingRect`
- using Vue as a thin wrapper around your business logic
- basic SVG

The source code is available [here](https://github.com/lmiller1990/vue-scroll-progress) and a working demo [here](https://lmiller1990.github.io/vue-scroll-progress/).