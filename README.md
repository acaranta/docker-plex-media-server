Plex Media Server Docker image
==============================

A slim Debian-based Docker image running the official [Plex Media Server](https://plex.tv/) as an unprivileged user, built for `linux/amd64` and `linux/arm64`.

Published on Docker Hub as [`acaranta/plex-media-server`](https://hub.docker.com/r/acaranta/plex-media-server).

> This is a fork of [wernight/docker-plex-media-server](https://github.com/wernight/docker-plex-media-server) by Werner Beroux. See [Credits](#credits) for what comes from upstream and what changed here.

![Plex Logo](docs/plex-logo.png)


Supported tags
--------------

  * [`latest`](latest/Dockerfile): the latest public Plex Media Server release at the time the image was built, for `linux/amd64` and `linux/arm64`.

The image is rebuilt regularly. To upgrade, pull `latest` again and recreate the container (Plex on Linux can't upgrade itself from the web UI).


What is Plex Media Server?
--------------------------

[Plex Media Server](https://plex.tv/) organizes your video, music, and photo collections and streams them to all of your screens (mobile, TV/Chromecast, laptop...).


How to use this image
---------------------

Provide two mount points writable by user `797` (the UID of the `plex` user inside the container; alternatively use the `--user` flag):

  * `/config`: holds your Plex configuration (media listing, posters, collections, playlists…). Without it you lose everything when the container is recreated.
  * `/media`: one or more of your media directories (videos, audio, images…).

```sh
mkdir ~/plex-config
chown 797:797 -R ~/plex-config
docker run -d --restart=always -v ~/plex-config:/config -v ~/Movies:/media --net=host acaranta/plex-media-server
```

Once done, wait a few seconds and open `http://localhost:32400/web` in your browser.

The flag `--net=host` is only required for the first run, so that you can log in locally without password (without SSH proxy) and see the "Server" tab in the web UI (see troubleshooting section below). Alternatively you can provide `X_PLEX_TOKEN` (see below). If you want **Avahi broadcast** to work then keep `--net=host` even after being logged in, but this will be somewhat less secure. Without host networking, publish the port instead: `-p 32400:32400`.

The `--restart=always` is optional; it allows, for example, auto-start on boot.

### Docker Compose

Depending on what you're streaming to, you may want to open more ports.
Example `compose.yaml` with the
[complete list of ports used by Plex](https://support.plex.tv/articles/201543147-what-network-ports-do-i-need-to-allow-through-my-firewall/):

```yaml
services:
  plex:
    image: acaranta/plex-media-server:latest
    ports:
      # for access to the Plex Media Server [required]
      - "32400:32400"
      # for access to the Plex DLNA Server
      - "1900:1900/udp"
      - "32469:32469"
      # for controlling Plex Home Theater via Plex Companion
      - "3005:3005"
      # for older Bonjour/Avahi network discovery
      - "5353:5353/udp"
      # for controlling Plex for Roku via Plex Companion
      - "8324:8324"
      # for current GDM network discovery
      - "32410:32410/udp"
      - "32412:32412/udp"
      - "32413:32413/udp"
      - "32414:32414/udp"
    volumes:
      - ./config:/config
      - ./media:/media
    #environment:
    #  - X_PLEX_TOKEN=<my_x_plex_token>
    #network_mode: host
    restart: unless-stopped
```


Features
--------

  * **Small**: built on the official Docker [Debian](https://hub.docker.com/_/debian) `bookworm-slim` image with the official Plex `.deb` package.
  * **Multi-arch**: [`latest/getplexdeb.sh`](latest/getplexdeb.sh) queries `https://plex.tv/pms/downloads/5.json` at build time and downloads the Debian package matching the target architecture (`amd64` → `linux-x86_64`, `arm64` → `linux-aarch64`, `arm` → `linux-armv7neon`).
  * **Secure**:
      * Runs Plex as the `plex` user (UID `797`), not root.
      * Downloads and installs the official binaries.
      * Uses [`dumb-init`](https://github.com/Yelp/dumb-init) as PID 1 to forward signals and reap zombie processes.
  * **Health check**: Docker checks `http://localhost:32400/` every 5 minutes.
  * **Logs**: the Plex Media Server log is streamed to the container's stdout (`docker logs`).


Environment Variables
---------------------

Variable                            | Default | Meaning
----------------------------------- | ------- | -------
`X_PLEX_TOKEN`                      | *(unset)* | Your [X-Plex-Token](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/). Written to `PlexOnlineToken` in `Preferences.xml` on start, to *register your server* without going through the web UI.
`PLEX_EXTERNAL_PORT`                | *(unset)* | External port (reachable from the internet) for your Plex server. Sets manual port mapping in `Preferences.xml`.
`PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS` | `6`     | Number of plugins that can run at the same time.
`PLEX_MEDIA_SERVER_MAX_STACK_SIZE`  | `3000`  | Stack size passed to Plex.

These are applied by [`latest/root/plex-entrypoint.sh`](latest/root/plex-entrypoint.sh) and the `ENV` defaults in [`latest/Dockerfile`](latest/Dockerfile). `X_PLEX_TOKEN` and `PLEX_EXTERNAL_PORT` are unset from the environment once written.

> **Note:** the upstream `PLEX_LOGIN` / `PLEX_PASSWORD` variables and the `retrieve-plex-token` helper are still present in the image but don't work: the helper needs `curl`, which the image doesn't install. Use `X_PLEX_TOKEN` instead.


Building locally
----------------

The image is built from the [`latest/`](latest/) directory. BuildKit sets `TARGETARCH`, which selects the Plex package:

```sh
docker buildx build --platform linux/amd64 -t plex-media-server:local latest/
```

[`latest/docker-compose.test.yml`](latest/docker-compose.test.yml) defines a `sut` service that starts Plex and checks it answers on port 32400.


Troubleshooting
---------------

  * I have to accept EULA each time?!
      * Did you forget to mount `/config` directory? Check also that it's writable by user `797`.
  * Cannot see [**Server** tab](http://localhost:32400/web/index.html#!/settings/server) from settings!
      * Try running once with `--net=host`. You may allow more IPs without being logged in by then going to Plex Settings > Server > Network > List of networks that are allowed without auth; or edit `your_config_location/Plex Media Server/Preferences.xml` and add `allowedNetworks="192.168.1.0/255.255.255.0"` attribute the `<Preferences …>` node or what ever your local range is.
  * Why do I have a random server name each time?
      * Either set a friendly name under Plex Settings > Server > General; or start with `-h some-name`.
  * Which port do I need to open on my firewall/router?
      * Even if you're using `--net=host` or `-p 0.0.0.0:32400:32400`, you'll still need to redirect port 32400 on your router to your machine running Plex, else you'll only be able to access it from within your LAN and you won't be able to Chromecast and other things. Remember to also check your firewall. Note that you can use another port if you so desire.

Backup
------

What you really need to back up (adapt `~/plex-config` to your `/config` mounting point):

  * Your media, obviously!
  * `~/plex-config/Plex Media Server/Media/`
  * `~/plex-config/Plex Media Server/Metadata/`
  * `~/plex-config/Plex Media Server/Plug-in Support/Databases/`

In practice, you may want to be safer and back up everything except maybe `~/plex-config/Plex Media Server/Cache/`
which is pretty large and you can really just skip it. It'll be rebuilt with the thumbnails, etc. as you had them.


Credits
-------

This image is derived from [**wernight/docker-plex-media-server**](https://github.com/wernight/docker-plex-media-server), created and maintained by [Werner Beroux](https://github.com/wernight), with contributions from Adrien (XciD) and David Warkentin. The entrypoint, `Preferences.xml` handling, token helper, health check and most of this documentation come from that project.

Changes in this fork:

  * Base image moved from `debian:buster-slim` to `debian:bookworm-slim`.
  * Multi-architecture build (`amd64`, `arm64`) with [`getplexdeb.sh`](latest/getplexdeb.sh) picking the right Plex package per architecture.
  * Published as [`acaranta/plex-media-server`](https://hub.docker.com/r/acaranta/plex-media-server).


License
-------

[MIT](LICENSE). Copyright © 2016 Werner Beroux (original work) and © 2020-2026 Arthur Caranta (modifications in this fork).

Issues with this image: [open a ticket on GitHub](https://github.com/acaranta/docker-plex-media-server/issues). Issues with Plex itself belong on the [Plex forums](https://forums.plex.tv/).
