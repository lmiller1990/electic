A static blog generator built to learn Elixir.

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

Then simply push to Github and enable `docs` as the homepage.

### Styles

Simply add to the relevant `.css` file in `/docs`.

### Todo:

- more tests
- better templates
  - about.html
  - contact.html
- theming?
- make available on mix
