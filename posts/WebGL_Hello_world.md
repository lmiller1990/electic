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

First we define the 
