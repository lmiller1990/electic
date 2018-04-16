## Introduction

ReactVR is an exciting new way to build 3D and VR environments, which can be easily deployed and accessed in a browser. One of the first things you will want to do in any web app is allow the user to interact with your creation. This leads to the topic of this post, handling events in ReactVR.

## Setup

There are lots of guides to get ReactVR set up. You can follow the [official documentation](https://facebook.github.io/react-vr/docs/getting-started.html). Basically:

```
npm install -g react-vr-cli
react-vr init EventsInReactVR
cd EventsInReactVR
npm start
```

Visiting `localhost:8081/vr` should yield the "hello" as shown in the official docs.

Before adding some code, let's talk about two important concepts.

## Cursors in Input

When handling eventsin ReactVR, there are two prerequisites you need to know about. __Cursors__, which let you trigger events, and __inputs__, which let you respond to them.

### Cursors

ReactVR implements cursors as __raycasters__. You can read more [here](https://en.wikipedia.org/wiki/Ray_casting), but basically a raycast is when a line is drawn in the direction of a cursor (for example, the mouse cursor) until it intecept something. More can be read [here](https://facebook.github.io/react-vr/docs/input.html#cursor-systems).


### Events
In ReactVR, raycasts continue and return when they collide with a view or mesh with at least one of the following:

1. `onEnter`
2. `onExit`
3. `onMove`

There is also one more event, `onInput`, which responds to all interactions: keyboard, mouse, touch, and gamepads. We will see all four events in action.

### `onMove` and `onEnter`

Let's write some code. Inside of `index.vr.js`, remove the boilerplate and add the following. An explanation of all the code follows.


```js
import React from 'react';
import {
  AppRegistry,
  Text,
  View,
  StyleSheet
} from 'react-vr';

const styles = StyleSheet.create({
  view: {
    width: 1,
    height: 1,
    backgroundColor: 'lime',
    transform: [{ translate: [0, 0, -1] }],
    layoutOrigin: [0.5, 0.5],
  }
})

export default class Events extends React.Component {
  render() {
    return (
      <View 
        onEnter={() => console.log('enter')}
        onExit={() => console.log('leave')}
        style={styles.view}
      >
      </View>
    );
  }
};

AppRegistry.registerComponent('Events', () => Events);
```

First we import some components. Normal React. The `styles` object is a bit more interesting. 

- in ReactVR, measurements are in __meters__. This means an object with a `height` and `width` of `1` will appear as 1 meter tall. 

- `transform: [{ translate: [0, 0, -1]} ]` moves the `<View>` __forward__ by 1 meter. In ReactVR, the user is facing -z by default. If we left it at [0, 0, 0], which is the default, the plane would be "on top" of us, and we would not be able to see it. Try changing the `-1` to `-0.5`, or `-2`.

- `layoutOrigin` moves the location of the view. `[0, 0]` is the top left hand coordinate of the view. By adjusting it by `0.5` on both the `x` and `y` axis, we center the view. Remember, the view is 1m height and 1m wide. Moving it 0.5m in both directions centers it.

__Note on transform__: the `transform` property is interesting. You can pass `scale` and `rotation`, and the order *is* important. [More here](https://facebook.github.io/react-vr/docs/3dcoordinates-and-transforms.html).

In `render`, we simply render the view with the stylesheet. We also set up listeners for the first two events we will look at, `onEnter` and `onExit`, which a `console.log` to verify they are working before moving forward.

If you typed everything correctly, refreshing `localhost:8081/vr` should show:

SS: view_1

Moving your cursor in and our of the view should print `enter` and `leave` messages in your console.

### `onMove`

Okay, so we see how `onEnter` and `onExit` work. `onMove` isn't much different, but let's see two quick examples of how it works, and what event properties are made available by ReactVR.

First, update the component as follows:

```js
// ... imports and stylesheet

export default class Events extends React.Component {
  constructor() {
    super()

    this.state = { count: 0 }
  }

  render() {
    return (
      <View 
        onMove={() => this.setState({ count: this.state.count + 1 })}
        style={styles.view}
      >
        <Text>
          {this.state.count}
        </Text>
      </View>
    );
  }
};

AppRegistry.registerComponent('Events', () => Events);
```

We remove the two previous events, and replaced them with `onMove`. Try refreshing and mousing over - you should see the `count` increasing on the screen - every frame you move your cursor inside the view.
