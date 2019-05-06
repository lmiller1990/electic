This post describes my experience organizing Rails controllers using only REST actions, an approach popularized by the mighty DHH and his cronies.

This article was published on 06/05/2019.

## Premise

As demoed by DHH [here](https://twitter.com/dhh/status/453188262002429952?lang=en) and explained in depth [here](http://jeromedalbert.com/how-dhh-organizes-his-rails-controllers/), organzing your Rails controllers with REST only actions, and then nesting sub controllers, you can make your application more consistent and approachable.

## Example

Let's say I have `posts` resource with your usual REST actions. Now I want to allow users to "correct" a post. One alternative is adding a `correction` route:

```rb
class PostsController < ApplicationController
  def correct
    # ...
  end
end
```

And in `routes.rb`, you would add the extra route. Something like:

```
resources :posts do
  get 'correct', controller: 'posts/correct'
end 
```

The pattern DHH and friends describe encourages you to make a new controller for any non standard REST method. So we make a new file in `app/controllers/posts/corrections_controller.rb`:

```rb
module Posts
  class CorrectionsController < ApplicationController
    def index
    end
  end
end
```

Now, since it is a "nested" resource, we naturally want access to the parent resource (eg, the `post`). The simple way would be to just do `@post = Post.find(params[:post_id])`. However, there is a convention that comes along with this nested controllers approach to create a concern to set the post for us. In `app/controllers/concerns/post_scoped.rb` add:

```rb
module PostScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_post
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
```

And in `posts/corrections_controller.rb`:

```rb
module Posts
  class CorrectionsController < ApplicationController
    include PostScoped

    def index
    end
  end
end
```

Now all the methods in the `CorrectionsController` have access to `@post`.

Lastly, `routes.rb` looks like this:

```rb
Rails.application.routes.draw do
  resources :posts do
    scope module: 'posts' do
      resources :corrections
    end
  end
end
```

## Conclusion

I am excited to try this pattern out. It seems clean and scalable.

