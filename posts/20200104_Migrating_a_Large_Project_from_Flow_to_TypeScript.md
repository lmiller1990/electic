Vue Test Utils uses Flow for type checking. I wanted to know what it would take to move to TypeScript.

[Vue Test Utils](https://github.com/vuejs/vue-test-utils) is the unit testing library for Vue.js. With Vue.js 3 on the horizon, and Vue Test Utils (VTU) still in beta, we are looking to get it over the line into a 1.0 release sooner rather than later. Aside from outstanding issues and open PRs, I've been thinking more about the long term maintainability of the library, and other important changes we might want to make prior to hitting 1.0. 

One of the main things that comes to mind is migrating from Flow to TypeScript. There was a time where both were completing for *the* premiere JavaScript type solution, however in recent years TypeScript has won a significant mind share. With Vue.js 3 been written in TypeScript as well, this seems like something that might be beneficial.

My criteria for a potential migration are as follows:

- should be incremental (eg, we both Flow and TS to exist side by side for a period of time). This way, we can migrate file by file, and ensure no bugs are introduced
- minimal changes to existing infrastructure

If you want to TL;DR, I forked the project and made a PR showing what code and configuration needs to change [here](https://github.com/lmiller1990/vue-test-utils/pull/1).

## How is Vue Test Utils Bundled?

Until attempting this migration, I didn't even really know how VTU was built or bundled, so it was a great learning experience! It turns out we use both [Webpack](https://webpack.js.org/) and [Rollup](https://github.com/rollup/rollup). They are pretty similar, but have slightly different use cases. 

Webpack is designed to bundle your assets via "loaders" - this means not just .js files, but html, images, svg, whatever you want. It also aims to provide a great developer experience by features like hot reloading.

Rollup aims to provide small bundles - this is why a lot of libraries, like Vue and React, are bundled with Rollup. A quote you will see regarding these two bundlers is "Webpack is for applications, Rollup is for libraries". Like anything, it depends on your use case.

For VTU, Rollup is used to build the packages. When you run `yarn build`, `yarn lerna build` is in turn executed. If you look at [`lerna.json`](https://github.com/vuejs/vue-test-utils/blob/dev/lerna.json), you can see it specifies a `packages` key. Inside the [`packages` directory](https://github.com/vuejs/vue-test-utils/tree/dev/packages) are the four packages that make up VTU. Each one has a `package.json`, which has a `build` script. The main package, "test-utils", runs `node scripts/build.js`.

Looking at [`build.js`](https://github.com/vuejs/vue-test-utils/blob/dev/packages/test-utils/scripts/build.js), you can see it is a Rollup configuration file. This is where we will need to tell Rollup how to handle `.ts` files.

## How are the tests run?

So now we know that VTU is built using `rollup`. How about the tests? It turns out `webpack` is used for the tests. If we look at the top level `package.json` file, the `test:unit:only` script runs `    "test:unit:only": "mocha-webpack --webpack-config test/setup/webpack.test.config.js test/specs --recursive --require test/setup/mocha.setup.js"`. This expects that you have already built and bundled the packages with `yarn build`. If you attempt to run the tests without having first run `yarn build`, you will get a ton of errors complaining about missing files (because you have not built them yet).

This is actually a nice way to do things - we separate the build and test configuration and logic. This way, when the tests run, they are just testing raw JavaScript - no need to know what type checker/bundler/babel/whatever.

## Migrating a Single File to TypeScript

Now we know how the build and test steps differ, let's attempt to move a file to TypeScript. I picked a small one, [`find-dom-nodes.js`](https://github.com/vuejs/vue-test-utils/blob/dev/packages/test-utils/src/find-dom-nodes.js). I just ran `mv packages/test-utils/src/find-dom-nodes.js packages/test-utils/src/find-dom-nodes.ts`. I then updated it with the minimal changes to make it a valid TypeScript file:

Before:

```js
// @flow

export default function findDOMNodes(
  element: Element | null,
  selector: string
): Array<VNode> {
  const nodes = []
  if (!element || !element.querySelectorAll || !element.matches) {
    return nodes
  }

  if (element.matches(selector)) {
    nodes.push(element)
  }
  // $FlowIgnore
  return nodes.concat([].slice.call(element.querySelectorAll(selector)))
}
```

After:

```ts
interface VNode {
  // ...
}

export default function findDOMNodes(
  element: Element | null,
  selector: string
): VNode[] {
  const nodes = []
  if (!element || !element.querySelectorAll || !element.matches) {
    return nodes
  }

  if (element.matches(selector)) {
    nodes.push(element)
  }
  return nodes.concat([].slice.call(element.querySelectorAll(selector)))
}
```

Ideally, I'll use the definition of `VNode` from the official Vue definitions. This is fine for a proof of concept.

Let's run it and see what happens! I ran `yarn build && yarn test:unit:only`.

```
$ node scripts/build.js
Error: Could not resolve './find-dom-nodes' from src/find.js ✘
info Visit https://yarnpkg.com/en/docs/cli/run for documentation about this command.

    at /Users/lachlan/code/projects/lachlan-vue-test-utils/node_modules/lerna/node_modules/execa/index.js:236:11
    at processTicksAndRejections (internal/process/task_queues.js:93:5) {
  code: 1,
  killed: false,
  stdout: '$ node scripts/build.js\n' +
    "Error: Could not resolve './find-dom-nodes' from src/find.js ✘\n" +
    'info Visit https://yarnpkg.com/en/docs/cli/run for documentation about this command.\n',
  stderr: 'error Command failed with exit code 1.\n',
  failed: true,
  signal: null,
  cmd: 'yarn run build',
  timedOut: false,
  exitCode: 1
}
```

The second line sums it up: `lerna ERR! Error: Could not resolve './find-dom-nodes' from src/find.js ✘`.

So, we need some way to change the `.ts` file into a `.js` to interop with the rest of the code base. Luckily, we are using rollup to bundle everything, and they have an [official TypeScript plugin](https://github.com/rollup/plugins). I added it with `yarn add @rollup/plugin-typescript tslib -W` at the root of the repository. I had to add `tslib` too, since they listed that as a dependency. I needed `-W` since I wanted to add it to entire workspace - we are using lerna to manage several packages in a single repository, and if you are doing this, you need to specify you are adding the dependency to the entire workspace.

Next, I updated `packages/test-utils/scripts/build.js`:

```js
const rollup = require('rollup').rollup
const flow = require('rollup-plugin-flow-no-whitespace')
const typescript = require('@rollup/plugin-typescript') // <- Added this require

// ... other imports ...

rollupOptions.forEach(options => {
  rollup({
    input: resolve('src/index.js'),
    external: ['vue', 'vue-template-compiler'],
    plugins: [
      typescript(), // <- added this
      flow(),
      json(),

    // ... other stuff ...
```

With a bit of luck, Rollup should now know how to process TypeScript files. Let's try the tests again by running `yarn build && yarn test:unit:only`:

```
 1112 passing (9s)
  1 pending

 MOCHA  Tests completed successfully
```

All the unit tests are working, which is great! Another part of the CI process is `yarn flow`, which runs the Flow type validation. Running `yarn flow`:

```
$ flow check
Error ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ packages/test-utils/src/find.js:3:26

Cannot resolve module ./find-dom-nodes.

     1│ // @flow
     2│
     3│ import findDOMNodes from './find-dom-nodes'
     4│ import {
     5│   DOM_SELECTOR,
     6│   REF_SELECTOR,
```

Presumably it's looking for a `.js` file - one does not exist, it's now a `.ts` file. I think the best approach here is to just `// $FlowIgnore` in `find.js`, since we cannot possibly expect Flow to know what to do with a `.ts` file. I updated import at the top of `packages/test-utils/src/find.js`:

```js
// @flow

// $FlowIgnore
import findDOMNodes from './find-dom-nodes'

// ...
```

Now `yarn flow` is happy! The last part is to run the full suite, including linting, browser tests using Karma, etc. I can do this with `yarn test`, which runs a much larger chain of commands, `npm run format:check && npm run lint && npm run lint:docs && npm run flow && npm run test:types && npm run test:unit && npm run test:unit:karma && npm run test:unit:node`.

Somewhat surprisingly, everything now works! I was expecting a bit more complexity, but Rollup is just awesome and everything worked out of the box. This seems like a viable way to incrementally move a code base from Flow to TypeScript. The final code diff is shown in a PR [here](https://github.com/lmiller1990/vue-test-utils/pull/1)

Whether VTU moves to TypeScript (pre 1.0, post 1.0, or ever) remains to be seen. However, if this is something that goes ahead, it looks like Rollup will make things super simple. I'm really excited for Vue.js 3, VTU finally hitting 1.0, and watching the front-end ecosystem develop in 2020.

