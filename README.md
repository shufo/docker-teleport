# docker-teleport

A docker image of [teleport](https://gravitational.com/teleport/). DockerHub repository is [here](https://hub.docker.com/r/shufo/teleport/).

You can use these tags as teleport version.

- `2.0.5`, `latest`

## Usage

- Run services in single node.

```
docker run -d -p 3080:3080 -p 3022-3025:3022-3025 shufo/teleport
```

- persistence

To persist the data (users, session), mount the host directory to `/var/lib/teleport` inside the container.
Or you can use [storage backend](http://gravitational.com/teleport/docs/2.0/admin-guide/#high-availability) in teleport v2.0 (DynamoDB, etcd) for data persistence.

```
docker run -v $(pwd)/teleport:/var/lib/teleport shufo/teleport
```

- Using custom teleport configuration file

To use custom configuration file, mount custom configuration file to `/etc/teleport.yml` inside the container.

```
docker run -v /path/to/teleport.yml:/etc/teleport.yml shufo/teleport
```

If custom configuration file is provided, custom environment value will be ignored.

## Environment Variables

### `TELEPORT_ROLES`

You can use `auth`, `proxy`, `node` as a teleport roles.


```
docker run -d -e TELEPORT_ROLES=proxy,node shufo/teleport
```

### `TELEPORT_AUTH_SERVER` `TELEPORT_TOKEN`

To specify auth server, you can use `TELEPORT_AUTH_SERVER` with `TELEPORT_TOKEN`.

```
docker run -d -e TELEPORT_ROLES=proxy,node -e TELEPORT_AUTH_SERVER=10.0.1.1:3025 -e TELEPORT_TOKEN=foobar shufo/teleport
```

### `TELEPORT_NODENAME`

To specify node name, you can use `TELEPORT_NODENAME` environment value.

```
docker run -d -e TELEPORT_NODENAME=teleport.example.com shufo/teleport
```

## Examples

### Separate hosts by roles

`docker-compose.yml`

```yaml
version: '2'
services:
  auth:
    image: shufo/teleport
    volumes:
      - ./teleport:/var/lib/teleport
      - ./teleport.yml:/etc/teleport.yml
    ports:
      - "3025:3025"
    expose:
      - 3025

  proxy:
    image: shufo/teleport
    ports:
      - "3023:3023"
      - "3024:3024"
      - "3080:3080"
    expose:
      - 3080
    environment:
      TELEPORT_ROLES: proxy
      TELEPORT_AUTH_SERVER: auth
      TELEPORT_TOKEN: all_your_base_are_belong_to_us

  node:
    image: shufo/teleport
    ports:
      - "3022:3022"
    environment:
      TELEPORT_ROLES: node
      TELEPORT_AUTH_SERVER: auth
      TELEPORT_TOKEN: all_your_base_are_belong_to_us
```

`teleport.yml`

```yaml
ssh_service:
  enabled: no
auth_service:
  enabled: yes
  tokens:
    - "node,proxy:all_your_base_are_belong_to_us"
proxy_service:
  enabled: no
```

### Nginx with automatically update certs by Let's Encrypt

In production environment, it is recommended to use certificates signed by CA.

To make it possible, we will use `nginx-proxy` and `letsencrypt-nginx-proxy-companion`.

- Create `docker-compose.yml` and replace `teleport.example.com`, and `LETSENCRYPT_EMAIL` with your own domain and email address.

`docker-compose.yml`

```yaml
version: '2'
services:
  teleport:
    image: shufo/teleport
    volumes:
      - ./teleport:/var/lib/teleport
      #- ./certs/teleport.example.com:/etc/teleport
      - ./teleport.yml:/etc/teleport.yml
    ports:
      - "3080:3080"
      - "3022:3022"
      - "3023:3023"
      - "3024:3024"
      - "3025:3025"
    expose:
      - 80
    environment:
      VIRTUAL_HOST: teleport.example.com
      VIRTUAL_PORT: 3080
      VIRTUAL_PROTO: https
      LETSENCRYPT_HOST: teleport.example.com
      LETSENCRYPT_EMAIL: your_email@example.com
    depends_on:
      - letsencrypt-nginx-proxy-companion

  nginx-proxy:
    image: jwilder/nginx-proxy
    ports:
      - 80:80
      - 443:443
    volumes:
      - /etc/nginx/vhost.d
      - ./certs:/etc/nginx/certs
      - /usr/share/nginx/html
      - /var/run/docker.sock:/tmp/docker.sock:ro

  letsencrypt-nginx-proxy-companion:
    image: jrcs/letsencrypt-nginx-proxy-companion
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    volumes_from:
      - nginx-proxy
```

- Create `teleport.yml`

```yaml
# By default, this file should be stored in /etc/teleport.yaml
teleport:
    # nodename allows to assign an alternative name this node can be reached by.
    # by default it's equal to hostname
    nodename: teleport.example.com
    #storage:
      #type: dynamodb
      #region: ap-northeast-1
      #table_name: teleport.state
      #access_key: BKZA3H2LOKJ1QJ3YF21A
      #secret_key: Oc20333k293SKwzraT3ah3Rv1G3/97POQb3eGziSZ

auth_service:
    enabled: true
    #
    # statically assigned token: obviously we recommend a much harder to guess
    # value than `xxxxx`, consider generating tokens using a tool like pwgen
    #
    # tokens:
    #  - "proxy,node:eiJieha0nie1yiequ4Joedou3NiDep"

ssh_service:
    # Turns 'ssh' role on. Default is 'yes'
    enabled: true

# This section configures the 'proxy servie'
proxy_service:
    # Turns 'proxy' role on. Default is 'yes'
    enabled: yes

    # SSH forwarding/proxy address. Command line (CLI) clients always begin their
    # SSH sessions by connecting to this port
    listen_addr: 0.0.0.0:3023

    # Reverse tunnel listening address. An auth server (CA) can establish an
    # outbound (from behind the firewall) connection to this address.
    # This will allow users of the outside CA to connect to behind-the-firewall
    # nodes.
    tunnel_listen_addr: 0.0.0.0:3024

    # The HTTPS listen address to serve the Web UI and also to authenticate the
    # command line (CLI) users via password+HOTP
    web_listen_addr: 0.0.0.0:3080

    # TLS certificate for the HTTPS connection. Configuring these properly is
    # critical for Teleport security.
    #https_key_file: /etc/teleport/key.pem
    #https_cert_file: /etc/teleport/fullchain.pem
```

- Run containers

```
docker-compose up -d
```

- Comment out the following lines to enable certificates.

```yaml
# docker-compose.yml

- ./certs/teleport.example.com:/etc/teleport

# teleport.yml

https_key_file: /etc/teleport/key.pem
https_cert_file: /etc/teleport/fullchain.pem
```

- Restart teleport to enable certificates.

```
docker-compose restart teleport
```

It's all done. Access to your web UI.

https://teleport.example.com/
