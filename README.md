# Status

- Concourse Version: 7.x
- Vault: 1.8.x
- Postgres: 11
- Auth: LDAP or Local
- Artifact-Storage: Minio S3 local storage
- Traefik as SSL-Offloader: 2.5+

## WAT

<img src="https://github.com/EugenMayer/concourseci-server-boilerplate/blob/master/assets/concourse.png" height="100"> <img src="https://github.com/EugenMayer/concourseci-server-boilerplate/blob/master/assets/vault.png" height="100"> <img src="https://github.com/EugenMayer/concourseci-server-boilerplate/blob/master/assets/minio.jpg" height="100"> <img src="https://github.com/EugenMayer/concourseci-server-boilerplate/blob/master/assets/openldap.png" height="100">

A boilerplate for you to quick-start a concourse stack with most of the features you would need in production.
It auto-configures `Concourse CI` and lets you configure most of the things using ENV variables for customization.

- [Concourse Configurator](https://github.com/EugenMayer/docker-image-concourse-configurator)
- [Vault](https://www.vaultproject.io/) (Secret Storage)
- [Minio](https://minio.io/) (S3 Artifact Storage)
- [LDAP](https://github.com/EugenMayer/docker-image-ldapexample) (Authentication)
- [Traefik](https://traefik.io/) (SSL Offloading)

It starts the whole stack with a simple

```console
docker-compose up
```

and lets you select the features you actually need in `.env`.

Use cases would be:

- Run Concourse CI in production
- Test concourse for or in your team
- test-drive upgrades of your concourse
- developing new pipelines before you deploy it to your production server, like this [concourse-app-release-lifecycle-example](https://github.com/kw-concourse-example/concourse-app-release-lifecycle-example)

## Usage

To just go for it:

`cp .env.local.sample .env`

```bash
docker-compose up

# or

./start.sh
```

Now you have the default setup. Access it using `http://localhost` (via traefik) with the user `included1`, password `included`

## Customizing

Copy the `.env.local.sample` to `.env` - now customize `.env`.

I. The default setup includes the following aspects

- `traefik` SSL offloading / reverse proxy (with disabled SSL by default)
- `vault` configured (as secret store), see `docker-compose-vault.yml`
- `minio` configured (as a s3 alike artifac storage store), see `docker-compose-minio.yml`
- `ldap` auth (an example ldap server is included, see `docker-compose-ldap-auth.yml` )
- local user auth `docker-compose-local-auth.yml`
- docker based workers `docker-compose-worker.yml`
- standalone workers (offsite) `docker-compose-worker-standalone.yml`

You can configure which aspects you want to pick by modifying `COMPOSE_FILE` in `.env`. So disable `vault` or `minio` or `ldap` as you please.

Please always consider to run your workers on a different machine / docker-engine then web in `production`.. they really kill each other.
I recommend running a standalone-worker on a non-docker engine VM in production (or several).

II. For the authentication, you have to pick at least `ldap` or `local` for auth

II. This will start a concourse server right up, including your aspects. The default is vault and ldap auth

    docker-compose up
    # or
    ./start.sh

## Examples

See examples including all the scripts to test your login, deploy test pipelines and pre-fill your vault for pipeline
testing

### Vault

See the `examples/run_3_vault_test.sh` script to see how consul con be setup and started with a vault based pipeline
`examples/vaults-based`

### Login / Credentials

The credentials for the first login depend on the auth type you have chose. Right now **Ldap** is the **default**

**Ldap**
When using the LDAP, potential users are listed here: https://github.com/EugenMayer/docker-image-ldapexample

- user: included1 / password: included1

See the [Concourse LDAP AUTH docs](https://concourse-ci.org/ldap-auth.html) if you want to lear more

**Local**

- user:admin / password: admin

See the [Concourse Local AUTH docs](https://concourse-ci.org/local-auth.html) if you want to learn more

### Access the WebUI

See "Login/Credentials" section for the login information, access the GUI :

    http://localhost

### Cli Configuration

Now install the cli

    # MacOS
    brew cask install fly

    # linux, e.g. arch AUR
    yay -S concourse-fly-bin

    # or download from the running concourse server

    # MacOS
    curl -o fly http://localhost/api/v1/cli?arch=amd64&platform=darwin

    # or Linux
    curl -o fly http://localhost/api/v1/cli?arch=amd64&platform=linux

now login with the cli against our local server

    fly -t test_main login -c http://localhost
    # see "Login/Credentials" for the login information

update fly

    fly -t test_main sync

Adjustments can be done by editing the .env file

### Create/Deploy a pipeline

push a pipeline to the main team / pipeline from `ci/pipline.yml`

    fly sp -t test_main configure -c ci/pipline.yml -p main --load-vars-from ../credentials.yml -n

## Minio s3 based storage

Having a proper artifact storage is basically a mandatory point with concourse-ci, maybe one of the key differences to other CI solutions
and for sure can be seen as a burden when you start concourse.
You can dodge it but you will regret it since concourse is stubborn in this regard - it will force it.
That is why Minio is included in this stack to provide an out of the box
s3 storage - locally. Without the hassle of s3 keys or similar.

**Be aware, Minio does not support object versioning, you will not be able to use `versioned_file: myapp.tgz` but only `regexp`**

To login, connect to

- http://localhost:9001
- user: minio
- password: changeme

You will need to create at leas one bucket to use it, obviously.
See https://github.com/kw-concourse-example/concourse-app-release-lifecycle-example for an example on how to use Minio
but basically its just the same as you would use AWS s3 - it's a "imitation"

## Intercept into a broken / running container

    fly -t test_main intercept -j <pipelinename>/<jobname>

so for example, assuming we have a job in pipeline `main` named `builder-image-build`

    fly -t test_main intercept -j main/builder-image-build

### Vault access and setting values

To adjust your vault or putting value into it, you should use the configurator container, which has the ability to talk to it
and set new values. Its pretty easy, just do

connect into the container

    docker-compose exec config bash

load credentials and server config

    source /vault/server/init_vars

set a value of your desire

    vault kv put secret/concourse/test value=test

or in short

    docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault kv put secret/concourse/main/firstvalue value=foo'

## Advanced

### Vault: Testing client access

since the above is all done using the server token, you can try the client token too

    docker-compose exec config bash

    export VAULT_CLIENT_CERT=/vault/concourse/cert.pem
    export VAULT_CLIENT_KEY=/vault/concourse/key.pem
    export VAULT_ADDR=https://vault:8200
    export VAULT_CACERT=/vault/concourse/server.crt

    vault login -method=cert
    vault kv get secret/concourse/main/main/myvalue
