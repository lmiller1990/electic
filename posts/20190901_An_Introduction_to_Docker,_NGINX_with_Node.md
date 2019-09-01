I started to learn devops recently. This article is basic tutorial on how to set up a node server, which receives requests via nginx.

This article was published on the 1st of September, 2019. The source code for the article is available [here](https://github.com/lmiller1990/nginx-reverse-proxy-docker-example).

## Setting up the Projects

First we will set up two projects - the node app and the nginx app (which is just config). Let's speed through the node app first, since nothing is very docker specific.

I have two directories, one called `node` and one called `nginx`. 

### Setting up the Node app

Inside the `node` I have a `package.json`:

```json
{
  "dependencies": {
    "express": "^4.17.1"
  }
}
```

And `index.js`:

```js
const express = require('express')

const app = express()

app.get('/', (req, res) => {
  res.json({ msg: 'hello from node' })
})

app.listen(3000, () => console.log('listening on 3000'))
```

Now it gets interesting. Add a `Dockerfile`:

```
FROM node:12-buster-slim

RUN mkdir -p /app
WORKDIR /app
COPY . /app
RUN npm install express
CMD ["node", "index.js"]
```

We specify the image - in this case, we want a copy of debian buster running node.js v12. You can see what other node images are available [here](https://hub.docker.com/_/node/).

We create a new directory called `app`, and set it are the current working directly. Then we copy all the files (which are `package.json`, and `index.js`) into `app`, and run `nopm install`. Lastly, we run `node index.js` to start the app.

That's it for the node project. If we added `EXPOSE 3000`, we would be then able to access the server from outside the container. But we want to let nginx handle that.

We can build the project with `docker build -t article_node:latest .`. After doing so, running `docker image ls` shows:

```
REPOSITORY           TAG                 IMAGE ID            CREATED             SIZE
article_node         latest              3bd5d5eb24be        16 seconds ago      163MB
```

Among other images. Great!

### Setting up nginx

Now it's time to set up nginx. In the `nginx` directly, add the following `Dockerfile`:

```
FROM nginx:alpine

COPY nginx.conf /etc/nginx/nginx.conf
```

We install nginx with a minimal linux distro, `alpine`. Then we copy a file, `nginx.conf`, which we are about to create, into `/etc/nginx/nginx.conf`, which is where nginx looks for configuration files.

Create `nginx.conf` with the following:

```
events {
}

http {
  server {
    listen 80;

    location / {
      proxy_pass http://node:3000/;
    }
  }
}
```

This is a simple `nginx.conf`. There are two top level sections: `events`, which I have not used before, and `http`. In `http`, we specify two options for the `server` section. The first is which port to listen on: http uses port 80 by convention. The next is `location`, which sets configuration based on a request URI. More info is [here](https://nginx.org/en/docs/http/ngx_http_core_module.html?&_ga=2.95412188.1718833636.1567336697-969308341.1567336697#location). 

By doing `location /`, we are matching ALL incoming requests. Since this simple nginx configuration is designed for the sole purpose of routing traffic to the node app, it's fine. You can specify more granular regexps here for more complex use cases, such as an app with many different services. 

We then set the [proxy-pass](https://nginx.org/en/docs/http/ngx_http_proxy_module.html?&_ga=2.95412188.1718833636.1567336697-969308341.1567336697#proxy_pass) attribute to `http://node:3000/` - this maps to port 3000 on the `node` domain. We will configure the naming for `node` soon - at the moment nginx has no idea what to do with `node`.

Build the nginx container by running `docker build -t article_nginx:latest .`. Now `docker image ls` yields:

```
REPOSITORY           TAG                 IMAGE ID            CREATED             SIZE
article_node         latest              3bd5d5eb24be        10 minutes ago      163MB
article_nginx        latest              142d2932f2d3        36 minutes ago      21.2MB
```

You can see how much smaller alpine linux is than debian buster, which we used for the node image.

## Bringing it together with docker compose

We will now use `docker-compose` to unite the two apps. At the top level, next to the `node` and `nginx` directores, create a `docker-compose.yml`. Inside it add the following:

```
version: '3'

services:
  node:
    image: article_node

  nginx:
    image: article_nginx
    ports:
      - 80:80
    depends_on:
      - node
```

By naming the service `node`, docker maps this to a network of the same name (I believe - it works, and if you name the service anything else, it will not work). We also expose port 80 from the nginx container to the same port on our local machine. We also add `depends_on`, which means when we run the `nginx` container, `node` will also start up.

You can run this in "detached" mode (in the background) by running `docker-compose up -d nginx`. To make sure it's working, do `curl localhost:80`. It should return `{"msg":"hello from node"}`. This means nginx is successfully proxying the request on port 80 to the node server, and then replying with the response! You can stop the containers by running `docker-compose down` (must be run in the directory with the `docker-compose,yml` of the container(s) you wish to stop).

## Conclusion

This article is a very simple introduction to docker, docker-compose and nginx as a reverse proxy.
