Options Composition API, JavaScript and TypeScript - one API and language to rule them all?

In this article, I will convert Vue.js 3 component built using regular JavaScript and the options API to use TypeScript and the Composition API. We will see some of the differences, and potential benefits. 

You can find the source code for this article [here](https://gist.github.com/lmiller1990/f12b847fc23592f25ab70b17074fe946).

Since the component has tests, and we will see if those tests are useful during the refactor, and if we need to improve them. A good rule of thumb is if you are purely refactoring, and not changing the public behavior of the component, you should not need to change you tests. If you do, you are testing implementation details, which is not ideal.

## The Component

I will be refactoring the `News` component. It's written using render functions, since Vue Test Utils and Jest don't have official support for Vue.js 3 components yet. For those unfamiliar with render functions, I commented the generated HTML. Since the source code is quite long, the basic idea is this markup is generated:

```html
<div>
  <h1>Posts from {{ selectedFilter }}</h1>
  <Filter 
    v-for="filter in filters" 
    @select="filter => selectedFilter = filter"
    :filter="filter"
  />
  <NewsPost v-for="post in filteredPosts" :post="post" />
</div>
```

This post shows some news posts, rendered by `<NewsPost />`. The user can configure which period of time they'd like to see news from using the `<Filter />` component, which basically just renders some buttons with labels like "Today", "This Week" etc.

I'll introduce the source code for each component as we work through the refactor. To give an idea of how a user interacts with the component, here are the tests:

```ts
describe('FilterPosts', () => {
  it('renders today posts by default', async () => {
    const wrapper = mount(FilterPosts)

    expect(wrapper.find('.post').text()).toBe('In the news today...')
    expect(wrapper.findAll('.post')).toHaveLength(1)
  })

  it('toggles the filter', async () => {
    const wrapper = mount(FilterPosts)

    wrapper.findAll('button')[1].trigger('click')
    await nextTick()

    expect(wrapper.findAll('.post')).toHaveLength(2)
    expect(wrapper.find('h1').text()).toBe('Posts from this week')
    expect(wrapper.findAll('.post')[0].text()).toBe('In the news today...')
    expect(wrapper.findAll('.post')[1].text()).toBe('In the news this week...')
  })
})
```

The changes I'll be discussing are:

- using the composition API's `ref` and `computed` instead of `data` and `computed`
- using TypeScript to strongly type `posts`, `filters`, etc.
- most importantly, which API I like, and the pros and cons of JS and TS

## Typing the `filter` type and Refactoring `Filter`

It makes sense to start from the simplest component, and work our way up. The `Filter` component looks like this:

```ts
const filters = ['today', 'this week']

export const Filter = defineComponent({
  props: {
    filter: {
      type: String,
      required: true
    }
  },

  render() {
    // <button @click="$emit('select', filter)>{{ filter }}/<button>
    return h('button', { onClick: () => this.$emit('select', this.filter) }, this.filter)
  }
})
```

The main improvement we will make it typing the `filter` prop. We can do this using a `type` (you could also use an `enum`):

```ts
type FilterPeriod = 'today' | 'this week'
const filters: FilterPeriod[] = ['today', 'this week']

export const Filter = defineComponent({
  props: {
    filter: {
      type: String as () => FilterPeriod,
      required: true
    }
  },
  // ...
)
```

You also need this weird `String as () => FilterPeriod` syntax - I am not too sure why, some limitation of Vue's `props` system, I suppose. 

This change is already a big improvement - instead of the reader trying to figure out what kind of `string` is actual a valid `filter`, and potentially making a typo, they can leverage an IDE and find out before they even run the tests or try to open the app.

We can also move the `render` function to the `setup` function; this way, we get better type inference on `this.filter` and `this.$emit`:

```ts
setup(props, ctx) { 
  return () => h('button', { onClick: () => ctx.emit('select', props.filter) }, props.filter)
}
```

The main reason this gives better type inference is that it is easier to type `props` and `context`, which are easily defined objects, to `this`, which is highly dynamic in JavaScript.

I've heard when Vetur, the VSCode plugin for Vue components is updated for Vue 3, you will actually get type inference in `<template>`, which is really exciting!

The tests still pass - let's move on to the `NewsPost` component.

## Typing the `post` type and `NewsPost`

`NewsPost` looks like this:

```ts
export const NewsPost = defineComponent({
  props: {
    post: {
      type: Object,
      required: true
    }
  },

  render() {
    return h('div', { className: 'post' }, this.post.title)
  }
})
```

Another very simple component. You'll notice that `this.post.title` is not typed - if you open this component in VSCode, it says `this.post` is `any`. This is because it's difficult to type `this` in JavaScript. Also, `type: Object` is not exactly the most useful type definition. What properties does it have? Let's solve this by defining a `Post` interface:

```ts
interface Post {
  id: number
  title: string
  created: Moment
}
```

While we are at it, let's move the `render` function to `setup`:

```ts
export const NewsPost = defineComponent({
  props: {
    post: {
      type: Object as () => Post,
      required: true
    },
  },

  setup(props) {
    return () => h('div', { className: 'post' }, props.post.title)
  }
})
```

If you open this in VSCode, you'll notice that `props.post.title` can have it's type correctly inferred.

## Updating `FilterPosts`

Now there is only one component remaining - the top level `FilterPosts` component. It looks like this:

```ts
export const FilterPosts = defineComponent({
  data() {
    return {
      selectedFilter: 'today'
    }
  },

  computed: {
    filteredPosts() {
      return posts.filter(post => {
        if (this.selectedFilter === 'today') {
          return post.created.isSameOrBefore(moment().add(0, 'days'))
        }

        if (this.selectedFilter === 'this week') {
          return post.created.isSameOrBefore(moment().add(1, 'week'))
        }

        return post
      })
    }
  },

  // <h1>Posts from {{ selectedFilter }}</h1>
  // <Filter 
  //   v-for="filter in filters" 
  //   @select="filter => selectedFilter = filter
  //   :filter="filter"
  // />
  // <NewsPost v-for="post in posts" :post="post" />
  render() {
    return (
      h('div',
        [
          h('h1', `Posts from ${this.selectedFilter}`),
          filters.map(filter => h(Filter, { filter, onSelect: filter => this.selectedFilter = filter })),
          this.filteredPosts.map(post => h(NewsPost, { post }))
        ],
      )
    )
  }
})
```

I will start by removing the `data` function, and defining `selectedFilter` as a `ref` in `setup`. `ref` is generic, so I can pass it a type using `<>`. Now `ref` know what values can and cannot be assigned to `selectedFilter`.

```ts
setup() {
  const selectedFilter = ref<FilterPeriod>('today')

  return {
    selectedFilter
  }
}
```

The test are still passing, so let's move the `computed` method, `filteredPosts`, to `setup`.

```ts
const filteredPosts = computed(() => {
  return posts.filter(post => {
    if (selectedFilter.value === 'today') {
      return post.created.isSameOrBefore(moment().add(0, 'days'))
    }

    if (selectedFilter.value === 'this week') {
      return post.created.isSameOrBefore(moment().add(1, 'week'))
    }

    return post
  })
})
```

This hardly changes - the only real difference is instead of `this.selectedFilter`, we use `selectedFilter.value`. `value` is required to access the `selectedFilter` - without `value`, you are referring to the `Proxy` object, which is a new ES6 JavaScript API that Vue uses for reactivity in Vue 3. If you open this in VSCode, you will notice that `selectedFilter.value === 'this year'`, for example, would be flagged as a compiler error. We typed `FilterPeriod` so errors like this can be caught by the IDE or compiler.

This final change is to move the `render` function to `setup`:

```ts
return () => 
  h('div',
    [
      h('h1', `Posts from ${selectedFilter.value}`),
      filters.map(filter => h(Filter, { filter, onSelect: filter => selectedFilter.value = filter })),
      filteredPosts.value.map(post => h(NewsPost, { post }))
    ],
  )
```

We are now returning a function from `setup`, so we not longer need to return `selectedFilter` and `filteredPosts` - we directly refer to them in the function we return, because they are declared in the same scope.

All the tests pass, so we are finished with the refactor.

## Discussion

One important thing to notice is I did not have to change my tests are all for this refactor. That's because the tests focus on the public behavior of the component, not the implementation details. That's a good thing.

While this refactor is not especially interesting, and doesn't bring any direct business value to the user, it does raise some interesting points to discuss as developers:

- should we use the Composition API or Options API?
- should we use JS or TS?

## Composition API vs Options API

This is probably the biggest change moving from Vue 2 to Vue 3. Although you can just stick with the Options API, the fact both are present will natural lead to the question "which one is the best solution for the problem?" or "which one is most appropriate for my team?". 

I don't think one is superior to the other. Personally, I find that the Options API is easier to teach people who are new to JavaScript framework, and as such, more intuitive. Understanding `ref`, `reactive`, and the need to refer to `ref` using `.value` is a lot to learn. The Options API, at the very least, forces you into some kind of structure with `computed`, `methods` and `data`.

Having said that, it is very difficult to leverage the full power of TypeScript when using the Options API - one of the reasons the Composition API is being introduced. This leads into the second point I'd like to discuss...

## Typescript vs JavaScript

I found the TypeScript learning curve a bit difficult at first, but now I really enjoy writing applications using TypeScript. It has helped me catch lots of bugs, and makes things much easier to reason about - knowing a `prop` is an `Object` is nearly useless if you don't know what properties the object has, and if they are nullable.

On the other hand, I still prefer JavaScript when I want to learn a new concept, build a prototype, or just try a new library out. The ability to write code and run it in a browser without a build step is valuable, and I also don't generally care about specific types and generics when I'm just trying something out. This is how I first learned the Composition API - just using a script tag and building a few small prototypes.

Once I'm confident in a library or design pattern, and have a good idea of the problem I'm solving, I prefer to use TypeScript. Consider how widespread TypeScript is, the similarities to other popular typed languages, and the many benefits it brings, it feels professional negligent to write a large, complex application in JavaScript. The benefits of TypeScript are too attractive, especially for defining complex business logic or scaling a codebase with a team.

Another place I still like JavaScript is design centric components or applications - if I'm building something that primarily operates using CSS animations, SVG and only uses Vue for things like `Transition`, basic data binding and animation hooks, I find regular JavaScript to be appropriate. The moment business logic or complexity creeps in, however, I like to move to TypeScript.

In conclusion, I like TypeScript a lot, and the Composition for that reason - not because I think it is more intuitive or concise than the Options API, but because it lets me leverage TypeScript more effectively. I think both the Options API and Composition API are appropriate ways to build Vue.js components.

## Conclusion

I demonstrated and discussed:

- gradually adding types to a component written in regular JavaScript
- good tests focus on behavior, not implementation details
- the benefits of TypeScript
- Options API vs Composition API 

