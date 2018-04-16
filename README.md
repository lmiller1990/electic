## Electic

A static blog generator built in Elixir, with the goal of push and deploy on Github pages. You can see an example of how this looks by visiting my blog, which is generated using Electic.

[Homepage](https://lmiller1990.github.io/electic/posts/custom_middleware_in_rails_5.html)
[Post](https://lmiller1990.github.io/electic/posts/custom_middleware_in_rails_5.html)

### About
Posts go in the `/posts` folder. They should be written in markdown.

Templates in the `/templates` folder. There are currently two:
- `index.html.eex`
- `show.html.eex`

### API
Generators:

`Electic.Generators.generate_post_html/1`

Takes a filepath as an argument. Example:

```ex
Electic.Generators.generate_post_html("posts/Mocking_the_filesystem_in_Elixir.md")
```

Which outputs in `docs/posts`.

`Electic.Generators.generate_index/0`  

Generates `index.html`, a list of all the posts in `docs/posts`. At the moment each post has to be generated manually using `Blog.Generators.generate_post_html/1`.

`Electic.Generators.generate_all_posts_html/0`  

Generates html for all posts in `/posts`.

`Electic.Utils.delete_all_existing_content/0`

Delete all existing content - this includes posts in `/posts` and content in `/docs`. You probably want to run this if you are using Electic for your own blog, since I committed all my posts alongside the project as I built it.

### Other

You can exclude a post from being added to `index.html` when executing `Electic.Generators.generate_index/0` by prepending the file name with `[draft]`. For example: `posts/[draft]This_post_is_not_ready.md`.

### Deploy
Simply push to Github and enable `docs` as the homepage.

### Styles

Simply add to the relevant `.css` file in `/docs`. To style the `posts/index.html.eex` you should add a `docs/index.css`. Likewise, to style `posts/show.html.eex`, you should add `docs/posts/show.html.eex`. I added a minimal stylesheet with syntax highlighting using prism.

### Todo:

- more tests
- better templates
  - about.html
  - contact.html
- theming?
- make available on mix
