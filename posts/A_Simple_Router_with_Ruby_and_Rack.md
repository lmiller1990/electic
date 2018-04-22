### A router from scratch with Rack and Ruby

Today I followed a guide by Adam Gamble about how to build a router for Rack, the class Ruby web server. The guide is [here](https://isotope11.com/blog/build-your-own-web-framework-with-rack-and-ruby-part-2).

## Rack Basics

A minimal Rack web server is as follows. Create a `Gemfile`:

```rb
source "http://rubygems.org"
gem "rack"
```

And run `bundle`. To create a simple Rack server, all you need is an object with the `call` method. `call` will be passed information about the web request. Create `lib/basic_controller.rb`:

```rb
class BasicController
  def call(env)
    [200, {}, ["Hello from basic controller"]]
  end
end
```

And a `basic_rack.ru` at the top level:

```rb
require 'rack'
load 'lib/basic_controller.rb'

Rack::Handler::WEBrick.run(
  BasicController.new, Port: 9000
)
```

And start the server using `rackup basic_rack.rb`. The following is displayed if everything went well

```sh
[2018-04-22 01:03:35] INFO  WEBrick 1.3.1
[2018-04-22 01:03:35] INFO  ruby 2.3.3 (2016-11-21) [universal.x86_64-darwin17]
[2018-04-22 01:03:35] INFO  WEBrick::HTTPServer#start: pid=36872 port=9000
```

As a quick aside:

### `load` and `require`

We are using both `load` and `require`. What is the difference?

Easy. Well, sort of. Basically, `load` will execute some code in a ruby file. You should pass an absolute path. When calling `load`, the following are imported:

- global variables
- classes
- constants
- methods

but *not* local variables. So when we did `load("lib/basic_controller.rb")`, we `load` the `BasicController` class. The `.rb`extension is also necessary. If you call `load` twice, the code will be executed twice.

`require`, on the other hand, only executes code once, even if you call it multiple times. `require` code is saved in a global variable called `$LOADED_FEATURES`.

## A better router

Now we know the basics of a Rack application. Let's make a more robust example, with controllers and a router.

Let's start fresh. Create a `Gemfile` and add Rack:

```rb
gem "rack"
```

Create a `config.ru` and include the following:

```rb
require 'bundler'
Bundler.require

require File.join(File.dirname(__FILE__), "lib", "main_rack")

```

Try running `rackup config.ru`. It will complain that `lib/main_rack.rb` doesn't exist. Create that, too, and add the following:

```rb
class MainRack
end
```

Run the app again (with `rackup config.ru`). Now we have a new error:

```sh
/Library/Ruby/Gems/2.3.0/gems/rack-2.0.4/lib/rack/builder.rb:146:in `to_app': missing run or map statement (RuntimeError)
```

This error is from Rack itself. Rack requires a `run` method, that takes a class with a `call` method. Recall the original `BasicController`:

```rb
class BasicController
  def call(env)
    [200, {}, ["Hello from basic controller"]]
  end
end
```

Go ahead and create `lib/request_handler.rb`.

```rb
class RequestHandler
  def call(env)
  end
end
```

Great! Now running the app gives us the default output for a Rack server starting:

```sh
[2018-04-22 18:05:50] INFO  WEBrick 1.3.1
[2018-04-22 18:05:50] INFO  ruby 2.3.3 (2016-11-21) [universal.x86_64-darwin17]
[2018-04-22 18:05:50] INFO  WEBrick::HTTPServer#start: pid=37786 port=9292
```

`curl localhost:9292` returns a 500 error, though. Inspecting Rack's output:


```sh
Rack::Lint::LintError: Status must be >=100 seen as integer
```

Right. `call` should return a status, headers, and a body. Let's do that.

```rb
class RequestHandler
  def call(env)
    [200, {}, ["ok"]]
  end
end
```

Now we can curl the Rack server. Let's move on to adding some routes.

### Adding a Router

We will store the `router` reference in `MainRackApplication.router`, which will have a `route_for` method, that decides which controller will handle the request. Update `request_handler.rb`:

```rb
class RequestHandler
  def call(env)
    route = MainRackApplication.router.route_for(env)
    if route
      # stuff
    else
      return [404, {}, []]
    end
  end
end
```

curling the server now will result in an error, since neither the `router` class, not the `route_for` method, exists. Create `lib/router.rb`, with just enough to let the server run again with `rackup config.ru` and curl it:

```rb
class Router
  def route_for(env)
  end
end
```

Also, update `lib_main_rack.rb` to `require` the router, and set an instance variable:

```rb
require File.join(File.dirname(__FILE__), 'router.rb')

class MainRack
  attr_reader :router

  def initialize
    @router = Router.new
  end
end
```

Now curling the server returns a 404, since `route_for` returns `nil`.

### Creating some routes

Before we implement the router logic and controllers, we need to decide on the DSL for the router. Let's make it like Rails'. Create `config/routes.rb`, and inside add two routes:

```rb
MainRackApplication.router.config do
  get "/users", to: "users#index"
  get "/users/show", to: "users#show"
end
```
We will define a `config` method on the `router`, which takes a block. Inside the block, we define a DSL of the following format:

```rb
[HTTP Verb] [path], to: "controller#method"
```

Soon we will use `instance_eval` to turn this into a function call to a method called `get`, which takes two arguments, a path and a hash of options including the controller and action.

Let's load the routes on startup. In `config.ru`, require `config/routes`:

```rb
# ...
require File.join(File.dirname(__FILE__), "config", "routes")
# ...
```

Now when start the app, we are calling `MainRack.router.config`, which throws an error since it doesn't exist. Let's make it exist:

```
class Router
  #...

  def config
  end
end
```

Okay, we can once again start the app without errors. But `config` doesn't do anything. What should it do, then?

### Registering the routes

Our goal is to create a hash called `@routes`, that we can use to look up the correct controller for each incoming request. Let's add an `attr_reader` and initialize an empty hash for the `@routes`. The hash will have a default value of an empty array. This means if you ask for an unknown key, you get an empty array by default.

```rb
class Router
  attr_reader :routes
  def initialize
    @routes = Hash.new{ |hash, key| hash[key] = [] }
  end

  # ..
end
```

Now onto config. We want the `@routes` hash to look like this:


```rb
{ :get => [
    "/test/show": {:klass => "TestController", :method => "show" }
  ]
}
```

Then if we get a `GET` request, we can loop all the `GET` routes, until we find the matching one. With this goal in mind, let's implement `config`:

```rb
def config(&block)
  instance_eval &block
end
```

This will produce the following, based on our `config/routes.rb` DSL:

```rb
get("users", { :to -> "users#show" })
```

So we need a `get` method, that takes a String path and an Hash of options.


```rb
def get(path, options={})
  @routes[:get] << [path, parse_opts(options[:to])]
end
```

We should format the `options` nicely. If we just did `[path, options[:to]]` we would get:

```rb
@routes[:get] = [
  [
    "/users/show", "users#show"
  ]
]
```

We want to split "users#show" to a hash with `controller` and `method` keys. Let's implement `parase_opts`:

```rb
def parse_opts(options)
  controller, method = options.split("#")
  {:controller => "#{controller.capitalize}Controller", :method => method}
end
```

Check it out by doing a `puts` after `instance_eval` in `config` and restarting the server:

```rb
Routes
{:get=>[["/users", {:controller=>"UsersController", :method=>"index"}], ["/users/show", {:controller=>"UsersController", :method=>"show"}]]}
```

Great!

### Adding Controllers

Now we have the routes set up. Let's add two simple controllers - a `BaseController` and a `UseresController`. Note we still have not implemented the logic to forward the request to the correct controller yet, but we do have a nice `@routes` hash that helps match requests to controllers. Create `app/controllers.rb`, and `app/controllers/base_controller.rb`, as wel las `app/controllers/users_controller.rb`.

First, add the following to `app/controllers/base_controller.rb`:

```rb
class BaseController
  attr_reader :env

  def initialize(env)
    @env = env
  end
end
```

This lets any controllers inheriting from `BaseController` access `env`, which contains all the information from Rack, such as the request path, headers, and so on.

Now add the following code to `app/controllers/users_controller.rb`:


```rb
class UsersController < BaseController
  def index
  end

  def show
  end
end
```

Remember, the controller has to return a response that complies to what Rack expects:

```rb
[status = 200, headers = {}, [body]]
```

Let's go ahead and make class for this. Add it in `lib/response.rb`:

```rb
class Response
  attr_accessor :status_code, :headers, :body

  def initialize
    @headers = {}
  end

  def rack_response
    [status_code, headers, Array(body)]
  end
end
```

Nothing too exciting. `@headers` aren't necessary, so they are set to an empty hash by default.

Now we can head back to `users_controller.rb` and implement `#index`.

```rb
def index
  Response.new.tap do |response|
    response.body = "Hello from users#index\n"
    response.status_code = 200
  end
end
```

`tap` is another way to assign instance variables on a new object. Instead of

```rb
response = Response.new
response.body = "..."

return response
```

We can do

```rb
Response.new.tap do |response|
  response.body = "..."
end
```

`tap` returns the newly created object instance.

We didn't `require` the newly added `response.rb`, so do that in `base_controller`. This will let all controllers access the `Response` object.

```rb
require File.join(File.dirname(__FILE__), "..", "..", "lib", "response")

class BaseController
  attr_reader :env

  def initialize(env)
    @env = env
  end
end
```

Okay. We actually have enough to see this working now. Let's finally do something in `router#route_for`. Before doing so, review `lib/request_handler.rb`:

```rb
class RequestHandler
  def call(env)
    route = MainRackApplication.router.route_for(env)
    if route
      # stuff
    else
      return [404, {}, []]
    end
  end
end
```

`route` should be a `response` object, with the format of:

```rb
[status = 200, headers = {}, [body]]
```

For now, update the `if` statement to return the `route`:


```rb
if route
  route
else
  return [404, {}, []]
end
```

Now in `lib/router.rb`:

```
def route_for(env)
  # this will get the first route, which is
  # ["/users", {:controller => "UsersController", :method => "index"}]
  route = @routes[:get].first

  # route it is an array. We are interested in the options, which is accessible by route.last

  options = route.last
  
  # create a new instance of the controller
  # UsersController inherits from BasicController, where #initialize requires and `env` argument
  controller = Module.const_get(options[:controller]).new(env)

  # this line calls #index, which returns a response instance
  res = controller.send(options[:method])
  
  # return the correctly formatted rack_response
  res.rack_response
end
```

If everything went well, you can restart the server and curling **any** url will return:

```sh
Hello from users#index
```

### Dynamically selecting the correct route

That was a lot of hardcoding, but it appears to be working! Let's refactor and allow the code to work for any route. The hardcode we need to make dynamic is:

- `require` the correct class for each route
- `send` the correct method for each request

 First, we can move the logic from `route_for` to a dedicated `route` object. Create `lib/route.rb`, and add:

```rb
require File.join(File.dirname(__FILE__), '../', 'app', 'controllers', 'base_controller')

class Route
  attr_accessor :controller, :path, :instance_method

  def initialize route_and_options
    @path, options = route_and_options
    
    @controller = options[:controller]
    @instance_method = options[:method]
  end
end
```

Each `route` will receive an array that has this shape:

```rb
[path = "/users", {:controller => "UsersController", :method => "index"}]
```

In `initialize` we assign the correct values to instance variables. The next thing is dynamically `require` the correct class:

```rb
def handle_requires
  require File.join(File.dirname(__FILE__), '../', 'app', 'controllers', underscore(@controller))
end

def underscore str
  str.gsub(/::/, '/').
  gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
  gsub(/([a-z\d])([A-Z])/,'\1_\2').
  tr("-", "_").
  downcase
end
```

We stole `underscore` from Rails - we need to change `UsersController` to `users_controller` and so forth.

Now we just need the logic to choose the correct controller (we required all the controller, but we also need to create and instance) and then use `send` to call the correct instance method that corresponds to the request:

```rb
def klass
  Module.const_get(@controller)
end

def execute(env)
  klass.new(env).send(instance_method)
end
```

Looking good. Now we can clean up the `route_for` method in `lib/router/rb`:

```rb
def route_for(env)
  path = env["PATH_INFO"]
  method = env["REQUEST_METHOD"].downcase.to_sym

  route_and_options = routes[method].find { |route|
    route.first == path
  }
  route_and_options ? Route.new(route_and_options) : nil
end
```

Pretty simple. We just find the corresponding `method`, in this case `:get`, and the matching path. We could improve this by checking for Regexp like the [original article](https://isotope11.com/blog/build-your-own-web-framework-with-rack-and-ruby-part-2). For now, simple is good.

Finally, we can update `lib/request_handler.rb`:

```rb
class RequestHandler
  def call(env)
    route = MainRackApplication.router.route_for(env)
    if route
      response = route.execute(env)
      return response.rack_response
    else
      return [404, {}, []]
    end
  end
end
```

And that's it! We can match any static route. Try restarting the application and executing `curl localhost:9292/users/ -i` and you should see:

```sh
HTTP/1.1 200 OK 
Transfer-Encoding: chunked
Server: WEBrick/1.3.1 (Ruby/2.3.3/2016-11-21)
Date: Sun, 22 Apr 2018 11:52:07 GMT
Connection: Keep-Alive

Hello from users#index
```

### Conclusion

Long article, but I learned a lot. You can find the original article [here](https://isotope11.com/blog/build-your-own-web-framework-with-rack-and-ruby-part-2). Ruby is really nice to work with and has a lot of great utlities for simple metaprogramming.
