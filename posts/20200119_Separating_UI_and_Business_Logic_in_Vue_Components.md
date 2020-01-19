One common occurrence I've observed across large Vue and React apps is that, over time, the UI logic and business logic becomes so entangled that UI changes break the business logic and vice versa. Let's look at an example of this, and how we can separate the concerns.

Mixed concerns also means the application has poor test coverage - unit tests often force you to keep your business logic and UI logic separate, and not doing so makes testing difficult. Tests aside, Vue and React are for building user interfaces, not encapsulating application logic, so there is a lot of value in keeping the two separate.

In this article, I will discuss separating business logic and UI logic by refactoring a password strength component posted by Milad Dehghan. You can see the original source code on his GitHub [here](https://github.com/miladd3/vue-simple-password-meter). You can try it out [here](https://miladd3.github.io/vue-simple-password-meter/).

A basic summary of how the component works is like this:

```html
<template>
  <div class="po-password-strength-bar" :class="passwordClass"></div>
</template>

<script>
export default {
  props: {
    password: {
      type: String,
      required: true
    }
  },
  computed: {
    passwordStrength() {
      if (this.password) {
        return this.checkPassword(this.password)
      }
    },

    passwordClass() {
      return [
        { scored: this.passwordStrength && this.password },
        {
          risky: this.passwordStrength === 0,
          // ...
          secure: this.passwordStrength === 4
        }
      ]
    }
  },
  methods: {
    checkPassword(pass) {
      // logic based on characters/length/numbers
      // returns a number between 0 - 4
      // 0 is the weakest, 4 is the strongest
    }
  }
}
</script>

<style>
.po-password-strength-bar.risky {
  background-color: #f95e68;
}

/* ... other styles */

.po-password-strength-bar.secure {
  background-color: #35cc62;
}
</style>
```

The `passwordClass` computed is a UI concern - depending on the number returned from `passwordStrength` computed property, a different `class` is returned and the relevant styling applied. `passwordStrength` is what would be a private method if JavaScript had private methods - it's basically a utility function that connects the UI and the main business logic, contained in `checkPassword`. 

`checkPassword` encapsulates all the business logic. It defines a number of regular expressions and applies them to the `password` prop. Depending on how many regular expressions match `password`, a different value between - 0 and 4 is calculated. If we decided we wanted to something a bit more robust, like [`zxcvbn`](https://github.com/dropbox/zxcvbn), we would make the change in this method.

## Planned Improvements/Refactors

The component currently works fine, and has no obvious problems. However, if I wanted to start using the component in production, there are some changes I'd like to make to give me confidence moving forward. Other than moving to a more robust password strength estimation algorithm. The improvements I'll investigate are:

- tests!
- separating the UI and business logic

Separating the business logic will make it very easy to accomplish my other goal of moving to a more secure password strength estimation algorithm.

## Writing a Regression Test

Before embarking on any refactor, I always write some basic regression tests. I want to make sure my changes do not break the existing functionality. I'll start by writing a test around the two extreme cases - an insecure password (score of 0, also known as "risky") and a secure password, with a score of 4.

```js
import { shallowMount } from '@vue/test-utils'
import SimplePassword from '@/SimplePassword.vue'

const riskyPassword = 'abcdef'
const securePassword = 'abc123ABC?!'

test('SimplePassword with a risky password', () => {
  const wrapper = shallowMount(SimplePassword, {
    propsData: {
      password: riskyPassword
    }
  })
  expect(wrapper.classes()).toContain('risky')
})

test('SimplePassword with a secure password', () => {
  const wrapper = shallowMount(SimplePassword, {
    propsData: {
      password: securePassword
    }
  })
  expect(wrapper.classes()).toContain('secure')
})
```

## Defining the `checkPassword` Interface

I want to have a minimal public interface that the `SimplePassword` component consumes. Specifically, I don't want `SimplePassword` to know about things like scoring systems - just the result: `risky`, `guessable`, `secure` etc. Since I'll be using TDD for this refactor, I'm going to write the test first. I'm only doing the two extreme cases for brevity, in a real system I would test all the cases.

```js
describe('checkPassword', () => {
  it('is a risky password', () => {
    const actual = checkPassword(riskyPassword)
    expect(actual).toBe('risky')
  })

  it('is a secure password', () => {
    const actual = checkPassword(securePassword)
    expect(actual).toBe('secure')
  })
})
```
 
Of course this is failing, the test does not have access to a `checkPassword` method at all, so it fails with `ReferenceError: checkPassword is not defined`. I'm going to create a `logic.js` file on the same level as `SimplePassword.vue` and move the `checkPassword` method from `SimplePassword.vue` to `logic.js`.

```js
export function checkPassword(pass) {
  // ... a bunch of variable declarations ... 

  if (pass.length > 4) {
    if ((hasLowerCase || hasUpperCase) && hasNumber) {
      numCharMix = 1;
    }

    if (hasUpperCase && hasLowerCase) {
      caseMix = 1;
    }

    if ((hasLowerCase || hasUpperCase || hasNumber) && hasSpecialChar) {
      specialChar = 1;
    }

    if (pass.length > 8) {
      length = 1;
    }

    if (pass.length > 12 && !hasRepeatChars) {
      length = 2;
    }

    if (pass.length > 25 && !hasRepeatChars) {
      length = 3;
    }

    score = length + specialChar + caseMix + numCharMix;

    if (score > 4) {
      score = 4;
    }
  }

  return score;
}
```

Now everything is failing, since `SimplePassword.vue` does not have a `checkPassword` method anymore. Let's update it:

```html
<script>
import { checkPassword } from './logic'

export default {
  name: "password-meter",
  props: {
    password: String
  },
  computed: {
    passwordStrength() {
      if (this.password) return checkPassword(this.password);
      return null;
    },
    passwordClass() {
      // ... omitted
    }
  }
}
</script>
```

I really like this refactor so far. The only change I made to `SimplePassword.vue` is:

```js
// import this
import { checkPassword } from './logic'

passwordStrength() {
  // change `this.checkPassword` to `checkPassword`
  if (this.password) return checkPassword(this.password);
  return null;
}
```

While it does not seem like much, this is already a big win. `checkPassword` is easier to test. Also, the change in `this.checkPassword` to `checkPassword` reflects the decoupling between business logic and UI logic. `this` refers to the Vue instance or component - so anything attached to `this` **should be related to your UI**. 

> Anything attached to `this` **should be related to your UI**.

`checkPassword` is also a pure function - no global variables of references to `this`, which means it's output is deterministic, based entirely on it's inputs. This is great for testing, and just feels generally great.

## Updating the `checkPassword` interface

Updating the test with `import { checkPassword } from '@/logic'` gives us this error:

```
Expected: "risky"
  Received: 0

Expected: "secure"
  Received: 4
```

Let's go ahead and update `checkPassword` to get the tests passing. The minimal change is to move the `passwordClass` from a `computed` into `logic.js`.

```js
function passwordClass(passwordStrength) {
  if (passwordStrength === 0) {
    return 'risky'
  }

  // ... others omitted for brevity ...

  if (passwordStrength === 4) {
    return 'secure'
  }
}
```

Notice we are not `exporting` the `passwordClass` function - this reflects what I stated earlier, that `passwordClass` is the equivalent of a `private` function in a language that supports that feature. 

Now we can update the `return` statement in `checkPassword` to use the new `passwordClass` method to get the `checkPassword` tests to pass

```js
export function checkPassword(pass) {
  // ... implementation ...
  return passwordClass(score);
}
```

Now the `checkPassword` tests are passing. The component tests are failing, though. Let's fix that!

```html
<script>
import { checkPassword } from './logic'

export default {
  // ...
  computed: {
    passwordClass() {
      if (this.password) {
        const className = checkPassword(this.password);

        return {
          [className]: true,
          scored: true
        }
      }
    }
  }
};
</script>
```

Now all the tests are passing.

We no longer have `passwordStrength` and `passwordClass`, or a bunch of `if` statements, since `checkPassword` defines a clean interface and encapsulates all the business logic. I really like this - `checkPassword` is very easy to test now, and the only code in the `script` tag of `SimplePassword` is directly related to the UI. It's also easy to switch out the password strength algorithm, - since we have the unit tests, I'll know immediately if I broke something.

There is also a nice symmetry in our tests - we have two tests using `render` which only make assertions against the CSS classes, and a number of tests around our business logic, which do not touch have knowledge of the `SimplePassword` UI concern.

## Conclusion

There are some other stylist improvements I'd like to make, but are mostly personal preference. We can be confident in making them, since we have decent test coverage. Separating the business logic and UI logic made the `SimplePassword` more understandable, and allowed us to improve test coverage. It also hid some of the implementation details, mimicing JavaScript's non existance `private` keyword.

There is a lot of value in separating UI and application logic; testability and readabilty for starters, and very little downside. Although it requires more thought up front, you end up with a better design and more maintainable codebase.
