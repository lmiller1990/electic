Rails is built on top of Rack, a general purpose Ruby HTTP server. Much of Rails comprises of Rack middlware (ActionDispatch, etc). Let's see how to add a custom middleware, as of Rails 5.

### Setup
Generate a new Rails 5 app by running:

```sh
rails new custom_middleware
```

Next, we will make a `middlewares` folder inside of `app`, with `my_middleware.rb`.

```sh
cd custom_middleware
mkdir app/middlewares
touch app/middlewares/my_middleware.rb
```

Inside of `my_middleware.rb`, add the following bare-bones middleware:

```rb
class MyMiddleware
  def initialize app
    @app = app
  end

  def call env
    status, headers, body = @app.call(env)
    puts "Middleware called. Status: #{status}, Headers: #{headers}"
    [status, headers, body]
  end
end
```

Lastly, we need to add the middleware. We can do this on a __per environment basis__, inside of `config/environments/[env]`. I will add `my_middleware` to `config/environments/development.rb`:

```rb
Rails.application.config do
  Rails.application.config.middleware.use MyMiddleware
end
```

Prior to Rails 5, you could do this ins `application/config.rb`, and as a String, not a Symbol. This doesn't seem to work as of Rails 5.

You can check the middlware stack by running `rake middleware`. You should see a bunch of other middlewares, like ActionDispatch, among others, and towards the bottom `use MyMiddleware`.

Start the rails app by running `rails server`, and visit any page. The log should show:


> Middleware called. 200, {"X-Frame-Options"=>"SAMEORIGIN", "X-XSS-Protection"=>"1; mode=block", "X-Content-Type-Options"=>"nosniff", "Content-Type"=>"application/json; charset=utf-8"}

I'll look at implementing a more interesting proxy middleware in a future post.
