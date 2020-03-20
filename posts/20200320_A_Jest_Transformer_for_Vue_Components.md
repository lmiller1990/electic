In this article, we build a transformer to change Vue 3 `.vue` component into a format Jest can understand. This is what `vue-jest` does, and how Vue Test Utils works. We will do this using a TDD like process: write what we want, and follow the errors to success.

## Getting Started

So, without further ado, we install `jest` and write a test:

```js
const Foo = require('./Foo.vue')

test('Loads a vue file', () => {
  console.log(document.body.outerHTML) // <div>Hello world</div>, eventually
})
```

Running `yarn jest` at this point This fails - we don't have a `Foo.vue`. Make one:

```html
<template>
  <div>
    Hello {{ world }}
  </div>
</template>

<script>
import { ref } from 'vue'

export default {
  setup() {
    return {
      world: ref('world')
    }
  }
}
</script>
```

Running this again with `yarn jest` gives us a new error:

```
Jest encountered an unexpected token

    ({"Object.<anonymous>":function(module,exports,require,__dirname,__filename,global,jest){<template>
                                                                                             ^
```

What do we do?!

## Using @vue/compiler-sfc

Jest does not know what to do with `<template>`. For this, we will pull in `@vue/compiler-sfc`! Install that, and the latest vue, with: `yarn add vue@3.0.0-alpha.8 @vue/compiler-sfc@3.0.0-alpha.8`.

The SFC compiler comes with a `parse` function. Jest transforms can be written in any file, as long as they export a `process` function. Make `index.js` that exports a `process` function:

```js
const { parse } = require('@vue/compiler-sfc')

module.exports.process = (source, filename) => {
  console.log(source)
}
```

And use the transform by creating a jest.config.js

```js
module.exports = { 
  transform: {
    '.vue$': './index.js'
  }
}
```

This was, all `.vue` files will be interpretted as the return value from `process`. Let's try `parse` in the `process` function:

```js
module.exports.process = (source, filename) => {
  const parsed = parse(source)
  console.log(parsed)
}
```

```js
{
  descriptor: {
    filename: 'component.vue',
    template: {
      type: 'template',
      content: '\n  <div>\n    Hello {{ world }}\n  </div>\n',
      loc: [Object],
      attrs: {},
      map: [Object]
    },
    script: {
      type: 'script',
      content: '\n' +
        "import { ref } from 'vue'\n" +
        '\n' +
        'export default {\n' +
        '  setup() {\n' +
        '    return {\n' +
        "      world: ref('world')\n" +
        '    }\n' +
        '  }\n' +
        '}\n',
      loc: [Object],
      attrs: {},
      map: [Object]
    },
    styles: [],
    customBlocks: []
  },
  errors: []
}
```

There is tons of good stuff here. We are interested in the `template` and `script` fields for now. Let's parse the template with `compileTemplate`, also from `@vue/compiler-sfc`:

```js
const { parse, compileTemplate } = require('@vue/compiler-sfc')

module.exports.process = (source, filename) => {
  const parsed = parse(source)
  const template = compileTemplate({ source: parsed.descriptor.template.content }).code
  console.log(template)

  return template
}
```

We get a render function! 

```js
'import { toDisplayString as _toDisplayString, createVNode as _createVNode, openBlock as _openBlock, createBlock as _createBlock } from "vue"\n' +
    '\n' +
    'export function render(_ctx, _cache) {\n' +
    '  return (_openBlock(), _createBlock("div", null, "Hello " + _toDisplayString(_ctx.world), 1 /* TEXT */))\n' +
    '}',
```

If we return it from `process we get "SyntaxError: Cannot use import statement outside a module"`. This is because it is using ES modules (`export` and `import`). We need some way for Jest to understand ES modules. We could use a preset, like `babel-jest`, or we can just compile the code ourselves using babel - I will be doing the latter. Install babel with `yarn add @babel/core` and use it:

## Transpiling with babel and babel preset

```js
// ...
const { transform } = require('@babel/core')

module.exports.process = (source, filename) => {
  // ...
  const template = compileTemplate({ source: parsed.descriptor.template.content }).code
  return transform(template)
}
```

Still no luck! We need to tell babel what to target with a preset - by default babel doesn't do a whole lot. We can use `preset-env`, which targets node module syntax by default. Install it with `yarn add @babel/preset-env`:

```js
const { parse, compileTemplate } = require('@vue/compiler-sfc')
const { transform } = require('@babel/core')
const babelPreset = require('@babel/preset-env')

module.exports.process = (source, filename) => {
  const parsed = parse(source)
  const template = compileTemplate({ source: parsed.descriptor.template.content }).code

  return transform(template, { presets: [babelPreset] })
}
```

Finally our test are green! No errors. - Mount the `Foo.vue` component:

```js
const { createApp } = require('vue')

const Foo = require('./Foo.vue')

test('Loads a vue file', () => {
  const el = document.createElement('div')
  el.id = 'app'
  document.body.appendChild(el)
  createApp(Foo).mount(el)
  console.log(document.body.outerHTML) // <div>Hello world</div>
})
```

Now we have `<div>Hello </div>`! Not bad - but where is `world`? There is also an error showing:

```
[Vue warn]: Property "world" was accessed during render but is not defined on instance.
      at <Anonymous> (Root)

  console.log index.spec.js:9
    <body><div id="app"><div>Hello </div></div></body>
```
## Combining template's render function and the script content

This above warning is happening because we are only returning the compiler `<template>` - what about the `<script>`? That's why `world` is not defined, and we get the warning. Let's compile the `<script>` tag in the same way:

```js
const { parse, compileTemplate } = require('@vue/compiler-sfc')
const { transform } = require('@babel/core')
const babelPreset = require('@babel/preset-env')

module.exports.process = (source, filename) => {
  const parsed = parse(source)
  const template = compileTemplate({ source: parsed.descriptor.template.content }).code

  const compiledTemplate = transform(template, { presets: [babelPreset] }).code
  const compiledScript = transform(parsed.descriptor.script.content, { presets: [babelPreset] }).code

  return // ????
}
```

We have now got two `module.exports` - `compiledTemplate` has one, `module.exports.default`, with all the content from the `<script>` tag. `compileTemplate` has `module.exports.render`. We need to combine them into a single `module.exports`... it's not pretty exactly, but we do so like this:

```js
  const compiledTemplate = transform(template, { presets: [babelPreset] }).code
  const compiledScript = transform(parsed.descriptor.script.content, { presets: [babelPreset] }).code

  return compileTemplate + compiledScript + '; module.exports = {...module.exports.default, render};'
```

Now we are rendering `<div>Hello world</div>` without any problems!

## Conclusion

We saw:

- using `@vue/compiler-sfc`, `parse`, and `compileTemplate`
- `process` to create a jest transformer
- how to use babel and babel preset to target node module syntax
