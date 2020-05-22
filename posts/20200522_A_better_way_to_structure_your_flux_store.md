This article discusses flux-entities, an abstraction I noticed after working on many different Vuex/Redux apps over the last few years. A more technical explanation and some example app can be found [on the GitHub page](https://github.com/lmiller1990/flux-entities).

## The Problem

I have worked with many companies who are using Vue and React, and almost all the Vue apps are using Vuex, and a number of React apps use Redux. Despite the consistency of a flux store, every single one has been dramatically different in structure. What's more, each "slice" of the state in each of these apps was basically arbitrary - the developers just created whatever fields were needed at the time, with little regard for consistency or maintainability.

Finally, a lot of these apps were written in JavaScript, not TypeScript, so without documentation or intricate knowledge of the application, knowing what data you were working with was very difficult. 

Let's look at one example, a small company building an esports analytics website. - it would show past, ongoing or upcoming games. When I joined, the front-end was hacked together in Vue by a few inexperienced designers. The fact they got this far with very little JS experience is a tribute to how powerful Vue is. Anyway, on to the Vuex store. Basically what the `src/store/games.js` looked like this:

```js
// src/store/games.js
const games = {
  state: {
    games: []
    currentGame: {},
    loaded: false,
    teamId: null
  }

  // a ton of mutations and actions and getters
}
```

This was basically a "god store" than held about 75% of the data in the app.

At first, it was very difficult to work on this app. There is no way to know what a `game` looks like, or when/how the `games` array is used. To represent a selected game, it was copied from the array into the `currentGame` object. This was to avoid looping 1000s of games to find the one that is currently selected.

There was no guidelines to how or where to save data, and things quickly became very difficult to reason about, and code turned to spaghetti.

There was also many other states in the store, other than game, but they most contained duplicated data, either too deep in the `games` array or just because it was easier that way. For example `src/store/teams.js` and `players.js`

```js
// teams.js
const teams = {
  firstTeam: null,
  secondTeam: null,
  currentTeam: {}
}

// players.js
const players = {
  data: [],
  selected: null
}
```

You can kind of guess what these might do. Turns the `teams` store also contained duplicates of players, with an array of games... things were messy.

This app, like many others, ultimately just wants to render lists, or a subset of a list. Considering this, and other apps I've worked on, I arrived at this list of thinsg we should optimize our store for:

- store a list of data
- keep track of load states (loading/loaded/error etc)
- keep track of a selected entity or object (in the above example, selected player/game)

With this knowledge, and armed with TypeScript (although not necessary) I arrived at a pattern I call `flux-entities`. I wrote about it [in the library README](https://github.com/lmiller1990/flux-entities). Let's expand on it with an example here, and make this esports app great again (although I don't think it exists anymore).

## Avoiding duplicated data; Keep your state flat!

The main problem I noticed is duplicating data throughout the flux store. In the above example, we have something like:

```js
// games store
const games = {
  games: [
    {
      id: 1,
      teams: [
        {
          id: 1,
          name: '...',
          players: [
            {
              id: 1,
              name: '...'
            }
          ]
        }
      ]
    }
  ]
}
```

Which represents the upcoming games. So far so good. This is fine when we are rendering a list of games. `v-for="game in games"`... suddenly, there was a request to add a feature where you could click a player, and see details stats, like their last 20 games. The solution at the time was to create a `player.js` store, hit an endpoint to get a response like this:

```js
[
  {
    id: 2,
    kills: 5,
    deaths: 2,
    team: {
      id: 4,
      result: 'win'
    }
  }
]
```

This went in the `player.js` store, which looks like this:

```js
const player = {
  id: 1,
  name: '...',
  careerKills: 1000,
  kda: 5.1,
  games: [] // past games and stats
}
```

The problem is we are now duplicating data - we have some overlap in `games` and player stats. This can lead to inconsistencies on the UI, and just a very confusing application to work on. Another problem the `games` array was large - even if you know the id of the selected game, you need to iterate over a large array to find it.

The solution is avoid nested state - refer to relationships using ids. I arrived at something like this:

```js
const games = {
  all: {
    '1': {
      redTeamId: '1',
      blueTeamId: '2',
      winnerId: '1'
    }
  },
  ids: ['1']
}

const teams = {
  all: {
    '2': {
      name: '...',
      players: ['1', '2', '3']
    }
  },
  ids: ['2']
}

const players = {
  all: {
    '1': {
      name: '...',
      currentTeam: '1',
      previousTeams: ['2', '3']
    },
  },
  ids: ['1']
}
```

Firstly, each state has the same shape. This won't work for all parts of your state, but it might for a lot of them - it has for me. Making each state similar makes it more predictable, allows you to share utility methods, and makes things more consistent in general.

The other thing to notice is we have no nested data, and no duplication. This solves a lot of problems. Furthermore, we are saving the data in an object called `all`, which is a key value map, instead of an array. We keep the `ids` in an array. This has a few benefits.

If you want to render a list of games, you just do

```html
<div v-for="id in $store.state.games.ids">
  {{ $store.state.games.all[id] }}
</div>
```

If you want to access a specific game, add a `selectedId` to the state. Now, instead of searching for it by looping over the `games` array, you can just do:

```html
<div v-if="$store.state.games.all[$store.state.games.selectedI]">
  {{ $store.state.games.all[$store.state.games.selectedId] }}
<div>
```

This is good! If you have 1000 games, access a specific one is an `O(n)` operation - worst case, you have to check 999 other games. By using an object, it's an `O(1)` operation.

If this seems verbose - it is. Define a helper - if you are using TypeScript, you get type-safety, too (`flux-entities` is written in TypeScript for this reason):

```ts
function selectedEntity(state) {
  return state.all[state.selectedId]
}
```

Now you just use a computed property:

```js
computed: {
  selectedGame() {
    return selectedEntity(this.$store.state.games)
  }
}
```

Since all your stores look the same, you can reuse `selectedEntity` for all of them.

## TypeScript to the rescue

Formally, we can define this `all` and `ids` combo like this with TypeScript:

```ts
const games = {
  all: Record<string, Game>
  ids: string[]
}

const players = {
  all: Record<string, Player>
  ids: string[]
}
```

Putting them into an interface we can reuse:

```ts
interface BaseState<T> {
  all: Record<string, T>
  ids: string[]
}
```

Now you just do:

```ts
const games: BaseState<Game> = {
  all: {},
  ids: []
}
```

We can upgrade our `selectedEntity` helper too:

```ts
function selectedEntity<T>(state: BaseState<T>) {
  return state.all[state.selectedId]
}
```

And you get type-safety.

### Load States

The other problem I often encounter was knowing when data has been loaded. Most apps have some kind of `loading` or `loaded` key in the state. The main situations I encountered in the esports app was:

- has the initial data loaded? (just show a spinner until then)
- did an error occur (show an error message)
- are we currently loading data?

Many apps use a combination of local component state and Vuex/Redux state. I ended up settling on these four keys in each of my state:

```js
const games = {
  all: {},
  ids: [],

  // for tracking load states
  touched: false,
  errors: [],
  loading: false,
  ready: false
}
```

- `touched` represents whether the initial data load has been triggered. If it is `false`, normally we want to trigger an API call
- `errors` is used when some error occurs. Often this might just be something like `['403: Access forbidden']`, but having an array gives flexibility. The app I work on now days is a medical device, and often we get several errors such as `['Patient weight is outside the model', 'Dose is too high']` for example.
- `loading` indicates an API request is in progress. Usually we want to show a spinner.
- `ready` indicates the initial API request has finished, and we can show the UI to the user.

I also use a number of helpers such as `isLoaded`, `isReady`, which just compute the state based on the status of `touched`, `errors` etc. Some parts of your store might not need these, if they are not storing data that is fetched from an API.

You can define a reusable interface using TypeScript for this, too:

```ts
interface AjaxState {
  touched: boolean
  errors: string[]
  loading: boolean
  ready: boolean
}
```

## Composing States

I use TypeScript, and the above architecture lends itself well to defining types using TypeScript. For example, since `flux-entities` has the interfaces mentioned above:

```ts
interface BaseState<T> {
  ids: string[]
  all: Record<string, T>
}
```

This is used for the `all` and `ids` part. `flux-entities` also has a `SelectableState`:

```ts
interface SelectableState {
  selectedId?: string
}
```

And `AjaxState`, which we defined above, with `touched`, `errors`, `ready` and `loading`.

If you need all three of those keys, you combine them:

```ts
interface UserState extends BaseState<User>, SelectableState, AjaxState {}
```

Better yet - use the built in interface that combines all three: `AjaxBaseSelectableState`.

Or mix and match as needed. You can read more about this architecture [on the GitHub page](https://github.com/lmiller1990/flux-entities), which also has some examples with Vue/Vuex, React/Redux, and vanilla js, or watch the accompanying screencast.

## Conclusion

This article primarily focused on my experience with Flux stores and the solution I abstracted. The most important point, though, is not the library or even my personal opinion on how your Flux store should look, but:

- consistency is key! Find common patterns and extract them. Make guidelines to allow your flux store and app to scale
- avoid duplicating data. Keeping a flat state is a good way to do this. Treat it like a relational database - relate entities with ids, or **references**, not by copy and pasting data across stores.
- a **single source of truth** is key to success with Vue/React and a flux store.
