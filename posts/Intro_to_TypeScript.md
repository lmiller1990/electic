I have been learning about TypeScript lately, since I will be using it at my new job, and I think type-safety can be valuable. This posts discusses some of the basic features of TypeScript.

This article was published on 11/11/2018.

## Interfaces

One of the best features of TypeScript is checking the _shape_ of a value.

## The First Interface

```ts
// good
function printLabel(labelObj: { label: string }) {
  console.log(labelOb)
}

// better
interface LabelValue {
  label: string
}

function printLabel(labelObj: LabelValue) {
  // ...
}

// or
function printLabel({ label }: LabelValue) {
  // ...
}
```

You can have an optional value with `?`:

```ts
interface Optional {
  val: string
  optionalNum?: number
}
```

## Readonly

`readonly` denotes a property that can only be assigned to on creation. 

```ts
interface Point {
  readonly x: number
}

let p1: Point = { x: 10 } // ok
let p2: Point = { x: 10 }
p2.x = 20 // bad
```

There is also a `ReadonlyArray` type in TypeScript:

```ts
let readOnlyArr: ReadonlyArray<number> = [1, 2, 3]
readOnlyArr.push(3) // bad
```

You can define the types of keys in an interface. Here is a full example. Interfaces can be nice to get type safety in Vuex stores:

```ts
interface ShapeConfig {
  id: number
  width: number
  height: number
}

interface ShapeConfigState {
  ids: number[]
  all: {
    [id: number]: ShapeConfig
  }
}

const square: ShapeConfig = {
  width: 100,
  height: 100,
  id: 1
}

 const rect: ShapeConfig = {
   id: 2,
   width: 100,
   height: 50
 }

const state: ShapeConfigState = {
  ids: [1, 2],
  all: {
    1: square,
    2: rect
  }
}
```

## Function Interfaces

You can use interfaces to describe functions, as well! Let's see how.

```ts
interface SearchFunc {
  (source: string, subString: string) : boolean
}

let mySearch: SearchFunc

mySearch = function(source: string, sub: string) {
  let result = source.search(sub)

  return result > -1
}
```

If `mySearch` had not returned a boolean, or declared `sub: number` instead, a compile time error would have been raised.

## Indexable Types

You can also use interfaces to describe indexes, for example:

```ts
interface StringArray {
  [index: number] : string
}

let myArray: StringArray
myArray = ["a", "b"] // ok
myArray = ["a", 1] // error
```

## Class Types

You can use interfaces to ensure a class meets some requirements:

```ts
interface ClockInterface {
  currentTime: Date
  setTime(d: Date): void
}

class Clock implements ClockInterface {
  currentTime: Date

  setTime(d: Date) {
    this.currentTime = d
  }

  constructor(h: number, m: number) {
    this.currentTime = new Date()
  }
}
```

## Difference between Static and Instance sides of classes

```ts
// for instance methods (instance side)
interface ClockInterface {
  tick(): void
}

// for constructor (static side)
interface ClockConstructor {
  new (hour: number, min: number): ClockInterface
}

function createClock(ctor: ClockConstructor, hour: number, min: number): ClockInterface {
  return new ctor(hour, min)
}

class DigitalClock implements ClockInterface {
  constructor(h: number, m: number) {}

  tick() {
    console.log('Tick tock...')
  }
}

createClock(DigitalClock, 12, 17)
```

The `ClockInterface` is used for ensuring classes that implement it are correct, and `ClockConstructor` for ensuring new instances are correct. Pretty neat.

## Extending Interfaces

Interfaces can extend each other.

```ts
interface Shape {
  color: string
}

interface PhysicalObject { 
  weight: number
}

interface Triangle extends PhysicalObject, Shape {
  sideCount: number
}

let tri1 = <Triangle>{ color: 'blue', sideCount: 3 } // ok... allowed to skip weight
let tri2: Triangle = { color: 'blue', sideCount: 3 } // not ok! Needs weight.
let tri3 = { color: 'red' } as Triangle // also ok
```

`tri2` is the only way to create an object and have the compiler check all the required properties are assigned.

## Hybrid Types

Sometimes you encounter an object that is both object-like and function-like. Consider:

```ts
interface Counter {
  (start: number): string
  interval: number
  reset(): void
}

function getCounter(): Counter {
  let counter = <Counter>function (start: number) {
    //  ...
  }

  counter.interval = 123
  counter.reset = function() { 
    // ...
  }

  return counter
}

const counter: Counter = getCounter()
counter("a") // error - should be a number
counter.reset() // ok!
counter.interval = 10
```

Factory functions often take this kind of form. Note the `Counter` interface has both a function signature `(start: number): string, an `interval` property and a `reset` property that is a function.`

## Interface Extending Classes

When an interface type extends a class:

- it __does__ inherit the members
- but __not__ their implementations

Here is an example:

```ts
class Control {
  private state: any

  setState(msg: string): void {
    this.state = msg
  }

  showState(): void {
    console.log(this.state)
  }
}

// interface extending class
// the interface will inherit the members but not their implementation
// this means that SelectableControl can __only__ be implemented by Control, or a subclass of it.
interface SelectableControl extends Control {
  select(): void
}

class Button extends Control implements SelectableControl {
  select() { 
  }
}

const b: Button = new Button()

b.setState("Hello")
b.showState() // Hello
```

If you want to provide a default implementation, you cannot use an interface. Instead, you can use an `abstract` class. Abstract classes cannot be directly instantiated.

```ts
abstract class BaseWidget {
  // will need to be implemented
  abstract getName(): string

  update(): void {
    console.log("Updating Widget...")
  }
}

class SideWidget extends BaseWidget {
  // if this is not implemented, the compiler will notify you.
  getName() {
    return "Side"
  } 
}

const sideWidget: SideWidget = new SideWidget()
console.log(sideWidget.getName())
sideWidget.update() // default implementation
```

## Generics

A generic is a component that can work across a variety of types - even ones yet to be created.

The most simple example is the "identity function".

## Hello World of Generics

First, without generics, the function looks like this:

```ts
function identity(arg: number): number {
  return arg
}
```

Or we could use `any`:

```ts
function identify(arg: any): any {
  return arg
}
```

Now it works with any type... but this is not very descriptive or useful. We may as well just use regular JavaScript. What we need is a way of capturing the type of the argument so we can denote what will be returned. We can use a __type varaible__, a variable that works on types rather than values.

```ts
function identify<T>(arg: T): T {
  return arg
}
```

This `T` allows us to capture the type the user provides (such as `string` or `number`). We can use this information later. Let's see how to call the `identify` function:


```ts
let output = identify<string>("myString") // type of the output will be string
```

You can also omit the `<string>` and leave it up to the compiler. Since `"myString"` is a string, `<T>` is set to `string` automatically. Now, let's see it in actions:

```ts
let num = identify({}) 
let str = identify("a")

let out = num - str // error! {} - a is not valid
```

This won't even compile:

```
src/test.ts(29,11): error TS2362: The left-hand side of an arithmetic operation must be of type 'any', 'number' or an enum type.
src/test.ts(29,17): error TS2363: The right-hand side of an arithmetic operation must be of type 'any', 'number' or an enum type.
```

So it shouldn't.

## Working with Generic Type Variables

Let's say we want to log the length of the variable, `T`.

```ts
function loggingIdentify<T>(arg: T): T {
  console.log(arg.length) // error.... T does not have a length property

  return arg
}
```

Makes sense... what if `T` is a `number`? `number` has no `length` property.

What if we intend to use `loggingIdentify` with an array of some kind objects? They would have a `length` property. We can write the function like this:

```ts
function loggingIdentify<T>(arg: T[]) : T[] {
  // ...
}

// or

function loggingIdentify<T>(arg: Array<T>) : Array<T> {
  // ...
}
```
