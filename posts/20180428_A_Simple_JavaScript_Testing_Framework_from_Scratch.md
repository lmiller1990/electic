In this article, I build a simple JavaScript framework from scratch. The framework will then be used to unit test itself
The goal is to be able to run this:

```js
describe('adder', () => {
  it('adds two numbers', () => {
    const result = adder(1, 2)
    expect(result).toBe(3)
  })
})
```

Let’s get started. The full source code is [here](https://gist.github.com/lmiller1990/8e17919503f119d656e96f55fccc4bc5) and tests are [here](https://gist.github.com/lmiller1990/9432684bd15704d5e4aa5554b4b86aed).

Create a new file called `index.js`. The entire source code will live inside here. Let’s start from `describe`.

### Describe

The `describe` function signature is `fn(description, callback)`. The first argument is simply a string describing the block, and the `callback` contains the actual test code to execute. It would be also be nice to print out the description when the test executes.

Relatively straightforward! Another nice part of this we can have arbitrarily nested `describe` blocks. For example:

```js
describe('outer', () => {
  describe('inner', () => {
  }
}

// outer
// inner
```

Surprisingly simple. Moving on...

### it

`it` is actually easier to implement than `describe`, at least for this example. Why? Let’s take a look at the function signature. The first argument is a `message`, and the second is the `callback`:

```js
fn(description, callback)
```

... which is identical to `describe`. Let’s just go ahead and use `describe`!

```js
const it = (msg, fn) => describe('  ' + msg, fn)
```

Now we just need to implement `expect(....).toBe(...)`.

### expect

Let’s start with `expect`. The function signature is as follows:

```js
expect(value).toBe(value)
```

Since we want to chain `.toBe`, expect must return an object that has a toBe property that is a method.

Start of by defining the expect method:

```js
const expect = (exp) => matchers(exp)
```

Now we can type `expect(1)` . We just need an object with a `toBe` property, that does the comparison between the value passed to expect and the value passed to `toBe`.

### matchers

The object returned by expect will contain at least one matcher, `toBe`, and possibly more in the future. It looks like this:

```js
const matchers = (exp) => ({
  toBe: (ass) => {
    if (exp === ass) {
      console.log('pass')
      return true
    } else {
      console.log('fail')
      return false
    }
  }
})
```

`exp` is the expected value, which is passed to expect. We need to pass it into matchers, to be able to make the comparison. toBe receives the assertion, which is what we expect to equal value passed to expect.

`toBe` is performing a strict comparison using `===.` This means `toBe` can only be used for primitives, such as String, Number and Boolean.

This is all we need to be able to run the example code from the start of the article! The full source code with example as follows, and can be pasted into a single `index.js` and run using `node index.js`.

```js
function adder(a, b) {
  return a + b 
}

const describe = (desc, fn) => {
  console.log(desc)
  fn()
}

const it = (msg, fn) => describe('  ' + msg, fn)

const matchers = (exp) => ({
  toBe: (ass) => {
    if (exp === ass) {
      console.log('pass')
      return true
    } else {
      console.log('fail')
      return false
    }
  }
})

const expect = (exp) => matchers(exp)

describe('adder', () => {
  it('adds two numbers', () => {
    const result = adder(1, 2)
    expect(result).toBe(3)
  })
})

module.exports = {
  describe,
  expect,
  it,
  matchers
}
```

I am exporting the methods at the bottom of the file, so I can require and test them.

### Testing the testing framework

As promised, we will test the framework using itself. I will write the tests in a file called `index.test.js`, which can be run using node `index.test.js`.

First, a test on `describe`.

### Testing `describe`

`describe`... actually doesn’t do much. It simply `console.log` a value, and executes the callback. We could mock `console.log` and ensure it is called, but that isn’t very interesting. Let’s focus on making sure the callback is called.

```js
const {
  describe,
  it,
  expect,
  matchers 
} = require('./index')

let executes = 0
const noop = () => { executes += 1 }

describe('describe', () => {
  it('returns a function', () => {
    const actual = describe('', noop)

    expect(executes).toBe(1)
  }) 
})
```

We start of by requiring all the functions we will test (and need to write the tests). We simply declare a `noop`, or no operation function that increments a value each time is it called — this is how we will assert that describe is calling the callback.

Testing `describe` is now as simply as asserting executes has indeed increments, which reflects that the `noop` callback did indeed execute.

### `it`

`it` just calls `describe`, and does nothing different, so testing is isn’t very interesting. 

### `expect`

`expect` is also very straight forward. expect returns an object, with a `toBe` property that is a `function`. 

```js
describe('expect', () => {
  it('returns an object', () => {
    const actual = expect(true)

    expect(typeof actual).toBe('object')
    expect(typeof actual.toBe).toBe('function')
  })
})
```

### `matchers.toBe`

`toBe` is as simple to test as everything else. It should return `true` for when primitives are equal, such as `1 === 1`, and false for `1 === 2`.

```js
describe('matchers', () => {
  describe('toBe', () => {
    it('works', () => {
      const actual = matchers('1').toBe('1')

      expect(actual).toBe(true)
    })
  })
})
```

Writing false is exactly the same, so I won’t include it.

### Conclusion and Improvements

`index.js`, not including whitespace and exports , is less than 30 lines of code! This isn’t a very full featured framework by any means, but for just 30 lines, it’s relatively powerful. Adding more matchers as as simply as adding extra methods to matchers. 

Building `isEqual`, `isTruthy` and are trivial. Add more advanced matchers like `toHaveBeenCalled` , and other test features like spies and mock functions are some improvements I’d like to implement, as well as better error handling and logger.
