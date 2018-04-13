I tried out ReactVR today, and so far I really like what I see! It was really easy to get going and when viewed from a phone, you really feel like you are in the scene.

ReactVR works by taking React components, and uses OVRUI (Oculus VR User Interface) to provide geometry information to Three.js. Three.js is a library that it built on to of WebGL. The WebGL code, and WebVR APIs (usually by Polyfill since the spec is still in active development) process the information and render the frame.

### Getting Started

Install the ReactVR tools by running:

```bash
npm install -g react-vr-cli
```

Then scaffold a new project, and start it up:

```bash
react-vr init ColorChanger

cd ColorChanger

npm start
```

Visiting `http://localhost:8081/vr/index.html` should render "hello" scene:

![react-vr](https://facebook.github.io/react-vr/img/hellovr.jpg)

Accesing this from your phone browser is where the real fun starts. As you move the device, the accelerometer detects the movement and manipulates the scene to make it feel as if you are *in* it.

### A first component

Let's make a new component. There is tons to learn, like how ReactVR handles 3D transforms, raytracers, and so forth. I will use two simple events (that internally use raytracing), `onExit` and `onEnter` to change the color of some text when it is clicked (or touched, depending on the user's input device).

```js
import React from 'react';
import { Text } from 'react-vr'

class ColorChange extends React.Component {
  constructor() {
    super()
    this.state = { textColor: 'white' }
  }

  render() {
    return (
      <Text
        style={{
          layoutOrigin: [0.5, 0.5],
          transform: [{translate: [0, 0, -3]}],
          color: this.state.textColor
        }}
        onEnter={() => this.setState({textColor: 'red'})}
        onExit={() => this.setState({textColor: 'white'})}>
      This text will change.
      </Text>
    )
  }
}

export default ColorChange
```

The main new stuff here is `layoutOrigin` and `transform`. `translate: [0, 0, -3]` means the `<Text>` will move 0m in the X and Y direction, and -3 in the Z direction. The default is the user is looking in then **-z** position. Or, __negative z is forwards__. That's why we set it to -3. If not, it would be at the default 0, on top of the user's port of view, which means we wouldn't be able to see it by default.

The `<Text>` default location is `0, 0`. We want to center the text, so we declare a `layoutOrigin` or `[0.5, 0.5]`.

Now we should `import` and use the component in `index.vr.js`:

```js
import React from 'react';
import ColorChange from './colorChange'
import {
  AppRegistry,
  asset,
  Pano,
  Text,
  View,
} from 'react-vr';

export default class WelcomeToVR extends React.Component {
  render() {
    return (
      <View>
        <Pano source={asset('chess-world.jpg')}/>
        <ColorChange />
      </View>
    );
  }
};

AppRegistry.registerComponent('WelcomeToVR', () => WelcomeToVR);
```

If everything went well the default screen should look like this:

If you mouse over (or touch on a mobile device) the font color should change:

### Conclusion

I will be learning more about ReactVR and trying different things out. Even as a OpengL framework, I think it is very powerful. I look forward to getting a pair of VR goggles to experiment with more.
