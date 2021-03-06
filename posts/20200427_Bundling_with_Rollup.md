In this article we will write a rollup config from scratch to compile a project written in TypeScript. Our goal will be three separate bundles:

- commonjs (extension `.cjs.js`, for use with node.js) 
- es module (extension `.esm-bundle.js`, for use with bundlers like webpack) 
- browser (extension `.browser.js`, for use in a browser)

We also will be including type definitions for TypeScript users.

## Building for node.js

Let's get started! If you want to follow along, grab VTU next at this point in history and delete everything from the `rollup.config.js`. Add `export default {}` and run `yarn rollup -c rollup.config.js`. You will get this error: 

```
Config file must export an options object, or an array of options objects
```

We will start with a object, for a single bundle, and an array when we include more. The minimal config we need is an `input`, the file to read from, and an `output`, which is where our bundled code will be written. Add the following:

```js
export default {
  input: 'src/index.ts',
  output: {
    file: 'vue-test-utils.cjs.js',
    format: 'cjs'
  }
}
```

Running this again gives us:

```
[!] Error: Could not resolve './mount' from src/index.ts
```
 
That's because rollup does not understand TS.

## Rollup Plugins

Rollup is minimal by design and does everything via plugins. We will use `rollup-plugin-typescript2`. What hapened to `rollup-plugin-typescript2`? No idea! We also need `json` to load `dom-event-types`, which exports a json file by default. Update the config:

```
import ts from 'rollup-plugin-typescript2'
import json from '@rollup/plugin-json'

export default {
  input: 'src/index.ts',
  plugins: [
    ts(),
    json()
  ],
  output: {
    file: 'vue-test-utils.cjs.js',
    format: 'cjs'
  }
}
```

Now it's compiling - with some warnings.


```
src/index.ts → vue-test-utils.cjs.js...
(!) Unresolved dependencies
https://rollupjs.org/guide/en/#warning-treating-module-as-external-dependency
lodash/isString (imported by src/utils.ts)
lodash/mergeWith (imported by src/utils.ts)
@vue/shared (imported by src/stubs.ts, src/utils/matchName.ts)
created vue-test-utils.cjs.js in 2.9s
✨  Done in 3.61s.
```

If we look at the top of our bundle, we see:

```
var isString$1 = _interopDefault(require('lodash/isString'));
var mergeWith = _interopDefault(require('lodash/mergeWith'));
var shared = require('@vue/shared');
```

On the first few lines. We need to decide if we want to bundle the source code for those dependencies in our project, or require the user to install them (either by specifying them as a `dependency` or `peerDependency`. We will opt for the latter - we want the user to provide their own version of those packages. Furthermore, if you scroll down the bundled file, you will notice it's almost 12000 lines - we are bundling the entire of Vue. This would make the user be stuck on the version of Vue we provide - not ideal. They will want to provide their own version.

## Using `external`

We can specify dependencies the user must provide using `external`. Update the config:

```
  external: [
    'vue',
    '@vue/shared',
    'lodash/mergeWith',
    'lodash/isString',
    'dom-event-types'
  ],
```

Now the warning is gone. Look at the bundle - it's only around 900 lines. The top shows the dependencies will be imported from `node_modules`, where the user will install them:

```
var vue = require('vue');
var isString = _interopDefault(require('lodash/isString'));
var mergeWith = _interopDefault(require('lodash/mergeWith'));
var shared = require('@vue/shared');
// ...
```

This should be enough to get us going. Let's try out the node.js build with the following script:

```js
require('jsdom-global')()
const { h } = require('vue')
const { mount } = require('./vue-test-utils.cjs.js')

const App = {
  render() {
    return h('div', 'Hello world') 
  } 
} 

const wrapper = mount(App)
console.log(wrapper.html())
```

Running this gives us `<div>Hello world</div>`! 

## Building for ES Modules

Now we have our cjs build, we will focus on the ES build. This will be used by bundlers, and uses the `import` and `export` syntax. We will also refactor our `config` into a `createEntry` function, so we can reuse it:

```js
import ts from 'rollup-plugin-typescript2'

function createEntry({ file, format }) {
  const config = {
    input: 'src/index.ts',
    plugins: [
      ts()
    ],
    external: [
      'vue',
      '@vue/shared',
      'lodash/mergeWith',
      'lodash/isString',
      'dom-event-types'
    ],
    output: {
      file,
      format
    }
  }

  return config
}

export default [
  createEntry({ format: 'cjs', file: 'vue-test-utils.cjs.js' }),
  createEntry({ format: 'es', file: 'vue-test-utils.esm.js' }),
]
```

Other than the refactor, all we did is change the format from `cjs` to `es`. If you run `yarn build`, get a second bundle - more or less the same, but with the ES module import/export syntax.

## Adding Type Definitions

We we want to provide type definitions for TS users, and so far all our bundles are in JS, so they won't have type definitions. We will just generate the type definitions once, when we compile the `es` module. Update `rollup.config.js` like so:

```js
import ts from 'rollup-plugin-typescript2'

function createEntry({ file, format }) {
  const config = {
    input: 'src/index.ts',
    plugins: [],
    external: [
      'vue',
      '@vue/shared',
      'lodash/mergeWith',
      'lodash/isString',
      'dom-event-types'
    ],
    output: {
      file,
      format
    }
  }

  config.plugins.push(
    ts({
      check: format === 'es',
      tsconfigOverride: {
        compilerOptions: {
          declaration: format === 'es',
          target: 'es5',
        },
        exclude: ['tests']
      }
    })
  )

  return config
}

export default [
  createEntry({ format: 'cjs', file: 'vue-test-utils.cjs.js' }),
  createEntry({ format: 'es', file: 'vue-test-utils.esm.js' }),
]
```

We just moved `ts` out of `plugins`, and conditionally check for `declaration` when the format is `es`. Now all the `.d.ts` files are generated.

## Bundling for the Browser

The final format we are aiming for is as a global variable in a browser. First, we will add a new `createEntry` call to our exported array:

```js
createEntry({ format: 'iife', input: 'src/index.ts', file: 'vue-test-utils.browser.js' })
```

`iife` is an immediately invoked function expression. This basically wraps our entire library in a function that is called immediately, to prevent any varibles from leaking into the global scope.

Next we will update the `output` key in the config:

```js
output: {
  file,
  format,
  name: 'VueTestUtils',
  globals: {
    vue: 'Vue',
    'lodash/mergeWith': '_.mergeWith',
    'lodash/isString': '_.isString',
  }
}
```

Again, we don't want to bundle Vue or lodash - the user will provide their own. Traditionally these are set to `Vue` and `_` respectively. `dom-event-types` and `@vue/shared` is a bit different - these are not common included in applications. As such, we are going to bundle this one with Vue Test Utils when it is used in a browser to make the development experience a bit more smooth. Update the config to only include `dom-event-types` and `@vue/shared` as external dependencies for the `es` and `cjs` builds:

```js
function createEntry({ file, format }) {
  const config = {
    // ...
    external: [
      'vue',
      '@vue/shared',
      'lodash/mergeWith',
      'lodash/isString',
    ],
    // ...
  }

  if (['es', 'cjs'].includes(format)) {
    config.external.push('dom-event-types')
    config.external.push('@vue/shared')
  }

  // ...
```

Now if we run this again, it is complaining:

```
(!) Unresolved dependencies
https://rollupjs.org/guide/en/#warning-treating-module-as-external-dependency
@vue/shared (imported by src/stubs.ts, src/utils/matchName.ts)
(!) Missing global variable name
Use output.globals to specify browser global variable names corresponding to external modules
```

Rollup doesn't know how to inline those dependencies. We have two - the `@vue/shared` dependency, a JS dependency, and the `dom-event-types`, which is really just a list of DOM events in a json file - see [here](https://github.com/eddyerburgh/dom-event-types/blob/master/dom-event-types.json). 

To include all of these, we need two plugins:

- resolve plugin
- commonjs plugin

To tell rollup how to bundle json files from `node_modules`. The error message does not suggest we need these at all - there isn't a great way to know this, without just playing around and observing the bundle. Anyway, adding those completes our config... almost:

```js
import ts from 'rollup-plugin-typescript2'
import resolve from '@rollup/plugin-node-resolve'
import json from '@rollup/plugin-json'
import commonjs from '@rollup/plugin-commonjs'

function createEntry({ file, format }) {
  const config = {
    input: 'src/index.ts',
    plugins: [
      resolve(), commonjs(), json()
    ],
    external: [
      'vue',
      'lodash/mergeWith',
      'lodash/isString'
    ],
    output: {
      file,
      format,
      name: 'VueTestUtils',
      globals: {
        vue: 'Vue',
        'lodash/mergeWith': '_.mergeWith',
        'lodash/isString': '_.isString',
      }
    }
  }

  if (['es', 'cjs'].includes(format)) {
    config.external.push('dom-event-types')
    config.external.push('@vue/shared')
  }

  config.plugins.push(
    ts({
      check: format === 'es',
      tsconfigOverride: {
        compilerOptions: {
          declaration: format === 'es',
          target: 'es5',
        },
        exclude: ['tests']
      }
    })
  )

  return config
}

export default [
  createEntry({ format: 'cjs', file: 'vue-test-utils.cjs.js' }),
  createEntry({ format: 'es', file: 'vue-test-utils.esm.js' }),
  createEntry({ format: 'iife', input: 'src/index.ts', file: 'vue-test-utils.browser.js' })
]
```

Let's try it out in the browser.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title></title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/lodash.js/4.17.15/lodash.js" integrity="sha256-kzv+r6dLqmz7iYuR2OdwUgl4X5RVsoENBzigdF5cxtU=" crossorigin="anonymous"></script>
  <script>
  </script>
    <script src="./vue.global.js"></script>
    <script src="./vue-test-utils.browser.js"></script>
</head>
<body>
  <button onclick="run()">Run</button>
</body>

<script>
  const App = {
    render() {
      return Vue.h('div', 'Hello world')
    }
  }

  VueTestUtils.mount(App) 
</script>
</html>
```

`vue.global.js` is the latest build of Vue 3 for the browser. Running this gives us... `ReferenceError: process is not defined`. Looking in `vue-test-utils.browser.js` for `process.env` shows:

```
const EMPTY_OBJ = (process.env.NODE_ENV !== 'production')
    ? Object.freeze({})
    : {};
```

This is from `@vue/shared` - since this is designed to be used as part of a build process with a bundler (such as when you build Vue 3) the Node process variable has not been replaced. We can do this with the `replace` plugin for Rollup:


```js
import replace from '@rollup/plugin-replace'

function createEntry({ file, format }) {
  const config = {
    // ...
    plugins: [
      replace({
        "process.env.NODE_ENV": true
      }),
      resolve(), commonjs(), json()
    ],

    // ...
```

Building this one final time and opening `index.html` in a browser shows the final, working browser build!

## Conclusion

We looked at Rollup, the bundler libraries, and how we can build for multiple formats:

- cjs (node.js)
- es modules (ES6)
- browser

We also discussed the different ways to include or exclude libraries in the builds, and their trade-offs. Find this config in the [Vue Test Utils Next repo](https://github.com/vuejs/vue-test-utils-next/).
