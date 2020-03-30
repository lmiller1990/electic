Vue 3 has a new feature called "Suspense". I find the naming to be a bit unintuitive - I had no idea what to expect when I first heard the name. I feel like a more descriptive name would be "LoadWithFallback" (although not as sexy). Anyway, today we will explore this new feature by building a simple app that shows some Covid19 (aka coronavirus) data.

## Parsing the dataset

The dataset I am using is found [here](https://github.com/pomber/covid19). I wrote some code to transform it - I wanted to get the total fatality count in each country. Let's take a look at the code and test:

The test looks like this:

```ts
import { parseData, Data } from './parseResponse'

const data = require('./covid19.json') as Data

test('parses covid19.json', () => {
  const expected: Record<string, number> = {
    Afghanistan: 3
  }

  const actual = parseData(data)

  expect(actual.Afghanistan).toBe(3)
})
```

I like to delcare my expected value, up front, with typings before I even start writing the test. It makes it clear what the code does, and the compiler can help me out if I make a mistake.

The actual implementation looks like this:

```ts
interface Day {
  date: string
  confirmed: number
  deaths: number
  recovered: number
}

export type Data = Record<string, Day[]>

const parseData = (data: Data): Record<string, number> => {
  const map: Record<string, number> = {}

  for (const [key, days] of Object.entries(data)) {
    if (!map[key]) {
      map[key] = 0
    }

    for (const day of days) {
      map[key] += day.deaths
    }
  }

  return map
}

export { parseData }
```

Nothing too exciting - we loop over the data and sum up the fatalities.

## Creating App.vue

We start off by defining `App.vue`, which contains the `<Suspense>` component. For now, let's focus on the `<template>`:

```html
<template>
  <div v-if="error">
    Error: {{ error }}
  </div>

  <Suspense v-else>
    <template #default>
      <DataTable />
    </template>

    <template #fallback>
      Fallback
    </template>
  </Suspense>
</template>
```

The first part is fairly simple - if there is an `error`, we render it. Next we have `<Suspense>`. When using `<Suspense>`, you need to provide templates. One is `#default`, which is a component with an `async setup` function. In this case, that will be `<DataTable>`. The other template is `#fallback`, which is displayed until the `async setup` function returns.

Before we get into any implementation details, let's look at the test. `<DataTable>` will make a HTTP call to fetch the Covid 19 data, so we need to consider the loading state, error state and success state. `App.spec.ts` looks like this:

```ts
describe('App', () => {
  test('data has not loaded', async () => {
    const wrapper = mount(App)

    expect(wrapper.html()).toContain('Fallback')
  })

  test('data has loaded', async () => {
    const wrapper = mount(App)
    await flushPromises()

    expect(wrapper.html()).toContain('Afghanistan: 3')
  })

  test('an error occurred', async () => {
    const wrapper = mount(App)
    await flushPromises()

    expect(wrapper.html()).toContain('An error occurred')
  })
})
```

The tests are pretty standard. One caveat is `flushPromises` - we will need this to force the `async setup` function to resolve, letting us test the success and error states.

## Implementing DataTable

The `<DataTable>` just makes a HTTP call with `axios`, then transforms the data using the `parseData` function we defined earlier.

```html
<template>
  <div v-for="country of countries" :key="country.name">
    {{ country.name }}: {{ country.deaths }}
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'
import axios from 'axios'

import { parseData } from './parseResponse'

export default defineComponent({
  async setup() {
    const response = await axios.get('/api/covid19')
    const data = parseData(response.data)

    return { 
      countries: Object.keys(data).map(name => ({ name, deaths: data[name] })
    }
  }
})
</script>
```

Pretty standard stuff - nothing here should be new, as long as you have some exposure to the Composition API. Let's use this in `App.vue`:


```html
<template>
  <!-- Omitted for brevity -->
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue'
import axios from 'axios'

import DataTable from './DataTable.vue'
import { parseData } from './parseResponse'

export default defineComponent({
  components: {
    DataTable
  },

  setup() {
    const error = ref<string | null>(null)

    return {
      error
    }
  }
})
</script>
```

## Testing Suspense

We need to mock `axios` in the test - let's do that. Add the following code to the top of `App.spec.ts`

```ts
import flushPromises from 'flush-promises'

import { mount } from '../src'
import App from './App.vue'

jest.mock('axios', () => ({
  get: () => {
    return { data: require('./covid19.json') }
  }
}))

describe('App', () => {
 // ..
})
```

Running this will get the first two tests - success and loading - to pass! Previously, you would have to have defined a `loading` variable, and did some `v-if` and `v-else` combination. `<Suspense>` makes this really clean.

The last test is pretty simple to get passing. We need some way to throw an error in the test. Update the `axios` mock, and the last test:

```ts
let mockShouldError = false 

jest.mock('axios', () => ({
  get: () => {
    if (mockShouldError) {
      throw new Error('ERROR!!!')
    }
    return { data: require('./covid19.json') }
  }
}))

describe('App', () => {
  // ...

  test('an error occurred', async () => {
    mockShouldError = true // <- added this
    const wrapper = mount(App)
    await flushPromises()

    expect(wrapper.html()).toContain('An error occurred')
  })
})
```

Setting `mockShouldError` will simulate the `axios` call erroring out. Finally, we need to handle the error in the component with `<Suspense>`, in this case `App.vue`. We do so with the `onErrorCaptured` hook:

```html
<template>
  <!-- Omitted for brevity -->
</template>

<script lang="ts">
import { defineComponent, onErrorCaptured, ref } from 'vue'
import axios from 'axios'

import DataTable from './DataTable.vue'
import { parseData } from './parseResponse'

export default defineComponent({
  components: {
    DataTable
  },

  setup() {
    const error = ref<string | null>(null)
    onErrorCaptured(e => {
      error.value = 'An error occurred'
      return true
    })

    return {
      error
    }
  }
})
</script>
```

Make sure you `return true` - otherwise the error will not be captured, and bubble up to the top of your app.

## Conclusion

This simple demo introduced the new `<Suspense>` component and `onErrorCaptured` hook, and showed how is simplifies the common use case of fetchign data asynchronously when a component is mounted.

