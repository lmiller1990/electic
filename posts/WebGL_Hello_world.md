First, we start by selecting the canvas element to which we will render the WebGL scene, and getting a reference to the WebGL context.

```js
function main() {
  const canvas = document.querySelector('#glCanvas')  
  const gl = canvas.getContext('webgl')
}
```

Next, we set up the vertex shader's uniforms and program entry point. __Uniforms__ are similar to JavaScript global variables, and can be accessed by both vertex and fragment shaders.

```js
const vsSource = `
  attribute vec4 aVertexPosition;

  uniform mat4 uModelViewMatrix;
  uniform mat4 uProjectionMatrix;

  void main() {
    gl_Position = uProjectionMatrix * uModelViewMatrix * aVertexPosition;
  }
`
```

The first line has a bunch of new information:

```js
attribute vec4 aVertexPosition;
```

An __attribute__ is used to communicate 'outside' of a vertex shader, kind of like a JavaScript global variable. Only the vertex andouter JavaScript code can access an attribute - a fragment shader cannot. `vec4` is a type - a vector with four points. For example:

```gl
new vec4(1.0, 2.0, 3.0, 1.0);
```

Next we have two more new concepts:

```js
uniform mat4 uModelViewMatrix;
```

Uniform is how shader programs communicate to the outside world - like attributes, but for fragment shaders, not vertex shaders. `mat4` is just another type, basically the same as an array. `mat4` means we get a 4x4 matrix, or:

```js
mat = [
  [0, 0, 0, 0],
  [0, 0, 0, 0],
  [0, 0, 0, 0],
  [0, 0, 0, 0],
]
```
