Setting up a complex stack for end-to-end tests is difficult and time consuming. Docker and docker-compose help solve this, at least in terms of running the various systems. You won't get a GUI though. Thit post looks at how you can run Cypress in a docker container and still use the interactive test runner using X11 to forward the UI to the host machine.

It looks like the best way to do this is to use [X Window System](https://en.wikipedia.org/wiki/X_Window_System). This also shows up in Google searches as X11 and X Server, which is confusing.

After some digging it turns out these names refer to subtly different things.

- X11 is a protocol. Specifically, the 11th version of the X protocol. It has been at version 11 since 1987 - it probably won't change.
- X Window System refers to the software architecture. So the ideas and framework around X11, and what an implementation needs to do to be X11 compliant.
- X.Org Server is the current reference implementation of the X Window System. It implements X11 (the latest version) of the protocol.

I am using a Mac for development. The reference implementation, [X.org](https://www.x.org/wiki/) is for Unix and Unix like environments. Luckily, there is a version (fork?) specifically for Mac OS - [XQuartz](https://www.xquartz.org/). You want to download and install this.

## Running Firefox in Debian + X11 Forwarding

Before messing around with Cypress, let's try and run Firefox in docker and forward the GUI using X11. The image I will use is `jess/firefox` (so grab it with `docker pull jess/firefox`).

We will add arguments one by one until everything works. Start off with the minimal command to run Firefox:

```
docker run --rm --name firefox jess/firefox
```

I get this error:

```
(firefox:1): Gtk-WARNING **: 05:50:11.788: Locale not supported by C library.
Using the fallback 'C' locale.
Error: no DISPLAY environment variable specified
```

I don't know what the first part is - it's a warning, so I should probably find out what it means at some point. For now we are concerned with: "Error: no DISPLAY environment variable specified". We need a `DISPLAY` environment variable. What it should be isn't entirely clear. You can see what yours is using `echo $DISPLAY`. One of my machines had nothing. The other had some random file I don't really understand with a path like `/private/tmp/com.apple.launchd......`. Neither of these is what we want. It should be set to the machine that will be the "host" for the X Window Server - the one where you want to show the GUI. In this case, the machine you are currently using.

## Getting Your Internal IP

There are many ways to get your internal IP. We will see the easy way, and the ninja way (which you can use in a script, so it's more convenient).

Normal way:

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/cyx11ip.png)

Or the ninja way using `ifconfig`. Run `ifconfig` if you like - you get a ton of network info. Each block has a name, like `en0`, `lo0` etc. You can read about them [here](https://stackoverflow.com/a/55232331/5231961). We want `en0`, that's the main internet port (en was for Ethernet, but now-days it is usually WiFi). Run `ifconfig en0`:

```
$ ifconfig en0
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
ether f8:ff:c2:29:7b:4c
inet6 fe80::cf5:ef5:b21c:ad71%en0 prefixlen 64 secured scopeid 0x9
inet 10.1.1.110 netmask 0xffffff00 broadcast 10.1.1.255
inet6 fddd:1b57:f3ad::1cce:189f:77d3:1e4b prefixlen 64 autoconf secured
inet6 fddd:1b57:f3ad::d533:3d47:fbe2:7423 prefixlen 64 autoconf temporary
nd6 options=201<PERFORMNUD,DAD>
media: autoselect
status: active
```

We want the internal IP address from the `inet` line. I don't know what the others are for yet, but I will find out one day. `grep` for it:

```
$ ifconfig en0 | grep inet
inet6 fe80::cf5:ef5:b21c:ad71%en0 prefixlen 64 secured scopeid 0x9
inet 10.1.1.110 netmask 0xffffff00 broadcast 10.1.1.255
inet6 fddd:1b57:f3ad::1cce:189f:77d3:1e4b prefixlen 64 autoconf secured
inet6 fddd:1b57:f3ad::d533:3d47:fbe2:7423 prefixlen 64 autoconf temporary
```

Finally we can use `awk` to get the IP address:

```
$ ifconfig en0 | grep inet | awk '$1=="inet" {print $2}'
10.1.1.110
```

We match the line where the first word is `inet` (`$0` represents the entire line in `awk`) then we print out the 2nd word.

## Running with a DISPLAY environment variable

Try running Firefox in docker, this time providing a `DISPLAY` environment variable:

```
$ DISPLAY=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}') \
docker run --rm --name firefox -e DISPLAY=$DISPLAY:0 jess/firefox
```

I get:

```
: Gtk-WARNING **: 06:26:29.131: Locale not supported by C library.
Using the fallback 'C' locale.
No protocol specified
Unable to init server: Broadway display type not supported: 10.1.1.110:0
Error: cannot open display: <DISPLAY>
```

Where `<DISPLAY>` will be different, depending on your system. One was the `/tmp/...` file from earlier, one was my `10.1.1.110:0` (my internal IP address).

Note that I added `:0` to the `DISPLAY` - that indicates the first "graphics controller" - again another term I don't fully understand.

## Open XQuartz

Open XQuartz, the X Window Server implementation for Mac. I had to go to "Preferences" (cmd + ,) -> Security -> Check Allow connections from network clients". I then had to *restart* my computer. Weird. I am not sure if this is always necessary but a lot of guides recommended it.

If you do a `ls -la ~/. | grep X` you will notice a ~/.Xauthority file was created. It is a cookie used for authenticating X sessions. [See more here.](https://askubuntu.com/questions/300682/what-is-the-xauthority-file).

Finally, we need a few more command line arguments.

```
DISPLAY=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}') \
docker run --rm --name firefox \
-e DISPLAY=$DISPLAY:0 \
-e XAUTHORITY=/.Xauthority \
-v ~/.Xauthority:/.Xauthority \
jess/firefox
```

The new arguments are:

- `-v ~/.Xauthority:/.Xauthority`. It maps the `.Xauthority` file on the host machine (your Mac) to a file called `.Xauthority` in the root directory of the docker container. 
- `-e XAUTHORITY=/.Xauthority`. Sets the `XAUTHORITY` environment variable to be that file. This will let the X Window server authenticate.

If I didn't miss anything, and neither did you, you should be able to run that command and run Firefox in a Debian locally!

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/cyx11ff.png)

## Cypress

Now we understand X11, we can apply this same approach to Cypress. I got a lot of information from [this blog post](https://www.cypress.io/blog/2019/05/02/run-cypress-with-a-single-docker-command/).

First I created a new Cypress project by installing Cypress with `yarn add cypress`. I ran Cypress once with `yarn cypress open`. It created a `cypress` directory with a bunch of example tests.

Now, run Cypress!

```
DISPLAY=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}') \
docker run --rm --name firefox \
-e DISPLAY=$DISPLAY:0 \
-e XAUTHORITY=/.Xauthority \
-v ~/.Xauthority:/.Xauthority \
-v $PWD:/e2e \
-w /e2e \
--entrypoint cypress cypress/included:3.2.0 open --project .
```

The main changes are:

- `--entrypoint cypress`. The Cypress binary is installed *globally* in this image. It will receive any arguments after the image - in this case `open --project .`. This will open the interactive runner and set the project directory to the current working directory.
- `-v $PWD:/e2e`. Map the current directory on the host (your laptop) to a directory called `/e2e` in the docker container. You can replace `/e2e` with anything.
- `-w /e2e` set the current working directory in the container to `/e2e`. It's like doing `cd /e2e` in the container.

![](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/cyx11cy.png)

## Conclusion:

- X11 is a protocol.
- X Window System is a framework designed aroudn X11.
- X.org is the reference implementation. XQuartz is a Mac OS compatible fork.
- To use X11 with Docker, you need X11 and a `DISPLAY` variable. `DISPLAY` is the host machine's IP. Include `:0` to specify the first graphics device.
- X Window System uses the `XAUTHORITY` environment variable and the session cookie is located at `~/.Xauthority`.

