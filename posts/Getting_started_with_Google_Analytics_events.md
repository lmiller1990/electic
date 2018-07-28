Recently I became more interested in how users are interacting with my sites. Google Analytics is a great tool for tracking this kind of data.

I want to know what features they are using, or not using, or having trouble with. This will let me spend my time most optimally.

I will make a simple test application in Rails, and get up Google Analytics events. When a button is clicked, I want to record the button clicked, and some additional data.

### Setting up Google Analytics

First, you will need an account. Visit [Google Analytics](https://www.google.com/analytics/#?modal_active=none), sign in, and visit the analytics tab.

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/ga_homepage.png)

### Add a new site

Click on "admin" in the bottom left hand corner, then click on "+ Create Account".

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/create_account.png)

We are testing on localhost, but GA requires a "real" url. We can use a virtual host to handle this. For now, you can use a placeholder. I am using my.domain.org. So under "Website URL", just enter that.

Now you will see this screen:

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/tracking.png)

Copy and paste the script that looks like this:

```js
<!-- Global site tag (gtag.js) - Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=UA-117322165-1"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'UA-117322165-1');
</script>
```

### Add the virtual host

On macOS, you can add a virtual host like so:

```sh
sudo vim /etc/hosts
```

Inside, add the following to use localhost with GA:

```sh
127.0.0.1 my.domain.org
```

### Make the Rails app and add the tracking script to `<head>`

I will use Rails for this demo. Create a new app but running:

```sh
rails new ga_test -T
```

and `cd` in. First things first, Open `app/views/layouts/application.html.erb` and add the GA script:


```html
<!DOCTYPE html>
<html>
  <head>
    <title>GaTest</title>
    <%= csrf_meta_tags %>

    <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track': 'reload' %>
    <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>


    <!-- Global site tag (gtag.js) - Google Analytics -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=UA-117322165-1"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());

      gtag('config', 'UA-117322165-1');
    </script>

  </head>

  <body>
    <%= yield %>
  </body>
</html>
```

### Adding the GA events

Make a new page to test tracking. We can use `rails g controller` to do so:

```sh
rails g controlls tests index
```

Now open `app/views/tests/index.html.erb` and add:

```html
<h1>Tests#index</h1>
<p>Find me in app/views/tests/index.html.erb</p>

<button onclick="sendEvent('button A')">
  Button A
</button>

<br>

<button onclick="sendEvent('button B')">
  Button B
</button>

<script>
function sendEvent(btn) {
  console.log(`Sending GA for ${btn}`)
  window.gtag('event', 'click', {
    event_category: 'button',
    event_label: btn,
  })
}
</script>
```

This will send a `event` of `click` type with the `event_label` as the button label.

### Try it out

Run the server with `rails server`, and visit `my.domain.org:3000/tests/index`. You must use the `my.domain.org`, and not `localhost`. Click the buttons a bunch of times, and head back to Google Analytics. Click "behavior", then "events" and "top events". You should be able to see the events! Sometimes it can take a bit of time to update. You can also visit the "real time" tab and watch the events update live.

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/events_page.png)

### Conclusion

GA events are a powerful tool to learn about users are interacting with your site, and the areas that need improvements, or more focus.
