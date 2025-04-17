# Newsroom Toolkit Hub 
Lightweight multi website server powered by [Newsroom Toolkit](https://nrtk.app) and [Caddy](https://github.com/caddyserver/caddy).

Caddy gracefully takes care of HTTPS (and obtaining certificates for your hosts) and serving your stuff to the people. Newroom Toolkit provides a modern CMS and a powerful API focused on your needs. This open source package combines the Newsroom Toolkit API with Caddy, adding a layer of independence, resiliency, and security to your website. Here is a [blog](https://joeface.com) is powered by this bundle.


## Key Features
* All-in-one solution for a self-hosted and secure websites
* Automated content synchronization based on [Go](https://github.com/Digital-Developments/nrtk-client-go) client
* Local backups and version control (you always have a snapshot of your content)
* SEO optimization via sitemap.xml
* Basic error page templates
* Open Source


## Getting Started
This guide assumes that you have:
* a standalone publication(s) on Newsroom Toolkit
* a domain(s) name that points to your instance public IP

To run website(s) using this package you will need [Docker Compose](#1-install-docker-compose) and [configure](#2-configure-hosts) your instance(s). 

### 1. Install Docker Compose
To run it you will need to [install](https://docs.docker.com/compose/install/) Docker Compose.


### 2. Configure Hosts
Create **.envs** directory in the project root and copy [host.example](host.example) into it:
```
$ cp .host.example .envs/host
```

and then configure your instance
```
NRTK_HOST_NAME="exmaple.com" - sets your website domain(s) (A-record should point to your instance IP-address)
NRTK_API_UUID="" - Your Newsroom Toolkit API Project ID
NRTK_API_TOKEN="" - Your Newsroom Toolkit API Token 
NRTK_HTTP_SERVER_ENABLED=1 - starts local HTTP server after launch
NRTK_HTTP_SERVER_PORT=8080 - port for your proxy 
NRTK_HTTP_SERVER_SYNC_HANDLER="/.sync-example-site-handler" - sync-hook path
NRTK_STORY_EXTENSION=".html" - adds .html extension to each story file
NRTK_APP_NAME="example" - how you wish to name the app
```
Repeat this step for each hostname/domain/project you wish to host on the Hub.

#### Caddy Configuration

Build [script](build.sh) will use this configuration data to generate Caddyfile content for all your hosts.

#### Alternative Caddy configuration
Let assume, you wish to attach Caddy configuration to Envs. In this case you may set multiple Envs for your caddy container:
```
HOST_1={host_name_1} {container_name_1} {proxy_port_1}
HOST_2={host_name_2} {container_name_2} {proxy_port_1}
...
HOST_N={host_name_N} {container_name_N} {proxy_port_1}
```

Then you may put this code in Caddyfile in the project root to enable reverse_proxy for each of the hosts:
```
(build_proxies) {
  {args[0]} {
        reverse_proxy {args[1]}:{args[2]}
  }
}

import build_proxies {$HOST_1}
import build_proxies {$HOST_2}
...
import build_proxies {$HOST_N}
```

The code above will generate a configutaion block for each host like this:
```
example.com {
    reverse_proxy nrtk-example:8080
}
```

### 3. Configure Docker Compose
Rename [compose-example.yml](compose-example.yml) into compose.yml:
```
$ mv compose-example.yml compose.yml
```

Here is the basic configuration of the host which creates a container based on [nrtk-client-go:0.1-alpine](https://hub.docker.com/repository/docker/michaelageev/nrtk-client-go/tags/0.1-alpine/sha256:1e733142dccac0bbc1863c37ea0350814e7d9d15f12727b98bfdb727fe7e0dee) image, exposes 8080 for reverse proxying for Caddy and uses configuration from the [previous step](#2-configure-hosts):
```
nrtk-host:
  image: michaelageev/nrtk-client-go:0.1-alpine
  restart: unless-stopped
  expose:
    - 8080
  volumes:
    - nrtk_data:/app/host/
  depends_on:
    - caddy
  env_file:
    - .envs/host
```

Feel free building your own client using it's [source code](https://github.com/Digital-Developments/nrtk-client-go).

You can add more hosts to the Hub using the template that extends nrtk-host service configuration:
```
nrtk-second:
  extends:
    service: nrtk-host
  volumes:
    - nrtk_data:/app/second/
  env_file:
    - .envs/second
```

### 4. Build & Launch 
Afterwards simply build Caddyfile and launch your Hub as a daemon:
```
$ bash build.sh
```

### 5. Check your website
Now it's time to check one of the hosts in your browser.


## License
The project is licensed under the GNU General Public License v3.0 (see the [LICENSE](LICENSE) file).