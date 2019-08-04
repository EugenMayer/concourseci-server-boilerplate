# Status

- Concourse Version: 5.x
- Vault: 1.2.x
- Postgres: 11
- Auth: LDAP or Local
- Artifact-Storage: Minio S3 local storage

## WAT

<img src="https://github.com/EugenMayer/concourseci-server-boilerplate/blob/master/concourse.png" height="100"> <img src="https://github.com/EugenMayer/concourseci-server-boilerplate/blob/master/vault.png" height="100"> <img src="https://github.com/EugenMayer/concourseci-server-boilerplate/blob/master/minio.jpg" height="100"> <img src="https://github.com/EugenMayer/concourseci-server-boilerplate/blob/master/openldap.png" height="100">

A boilerplate for you to quick-start a concourse stack with most of the features you would need in production.
It auto-configures `Concourse CI` and lets you configure most of the things using ENV variables for customization.

 - [Vault](https://www.vaultproject.io/) (Secret Storage)
 - [Minio](https://minio.io/) (S3 Artifact Storage)
 - [LDAP](https://github.com/EugenMayer/docker-image-ldapexample) (Authentication)

It starts the whole stack with a simple

```console
docker-compose up
```

and lets you select the features you actually need in `.env`.

Use cases would be: 

- Test concourse for or in your team
- test-drive upgrades of your concourse
- developing new pipelines before you deploy it to your production server, like this [concourse-app-release-lifecycle-example](https://github.com/kw-concourse-example/concourse-app-release-lifecycle-example)

## Upgrade from 4.x

-  it seems like fly 4.x cannot upgrade itself since it fails to authenticate against 5.x, so download it manually using
 - MacOS: `curl -o fly http://localhost:8080/api/v1/cli?arch=amd64&platform=darwin`
 - Linux: `curl -o fly http://localhost:8080/api/v1/cli?arch=amd64&platform=linux` 

and replace your binary in e.g. `/usrl/local/bin/fly`
 
## Start

I. First you have to choose which features you want or keep the default which is `vault+ldap+minio`

 - `vault` configured (as secret store), see `docker-compose-vault.yml`
 - `minio` configured (as a s3 alike artifac storage store), see `docker-compose-minio.yml`
 - docker based workers `docker-compose-worker.yml`
 - standalone workers (offsite)  `docker-compose-worker-standalone.yml`
 - `ldap` auth (an example ldap server is included, see `docker-compose-ldap-auth.yml`  )
 - local user auth `docker-compose-local-auth.yml`

You can configure which aspects you want to pick by modifying `COMPOSE_FILE` in .env.

II. For the authentication, you have to pick at least `ldap` or `local` for auth 
 
II. This will start a concourse server right up, including your aspects. The default is vault and ldap auth

    docker-compose up

## Configuration 

Now install the cli

    # MacOS
    brew cask install fly
    
    # linux, e.g. arch AUR
    yay -S concourse-fly-bin
    
    # or download from the running concourse server
    
    # MacOS
    curl -o fly http://localhost:8080/api/v1/cli?arch=amd64&platform=darwin

    # or Linux
    curl -o fly http://localhost:8080/api/v1/cli?arch=amd64&platform=linux    

now login with the cli against our local server

    fly -t test_main login -c http://localhost:8080
    # see "Login/Credentials" for the login information   

update fly
    
    fly -t test_main sync
    
Adjustments can be done by editing the .env file    

### Login / Credentials

the credentials for the first login depend on the auth type you have chose. Right now **Ldap** is the **default**

**Ldap**
When using the LDAP, potential users are listed here: https://github.com/EugenMayer/docker-image-ldapexample
- user: included1 / password: included1

See the [Concourse LDAP AUTH docs](https://concourse-ci.org/ldap-auth.html) if you want to lear more

**Local**
- user:admin / password: admin

See the [Concourse Local AUTH docs](https://concourse-ci.org/local-auth.html) if you want to learn more
    
### Access the WebUI
See "Login/Credentials" section for the login information, access the GUI :   

    http://127.0.0.1:8080
            
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
- password: changme

You will need to create at leas one bucket to use it, obviously. 
See https://github.com/kw-concourse-example/concourse-app-release-lifecycle-example for an example on how to use Minio
but basically its just the same as you would use AWS s3 - it's a "immitation"

    
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

### Running the standalone worker

`docker-compose-worker-standalone.yml` illustrates on how to utilize `eugenmayer/concourse-worker-configurator` to run an offsite standalone worker using ENV variables to deploy
the `worker private key` and `tsa public key`.

All you basically need is setting this ENV variables in the `eugenmayer/concourse-worker-configurator` container

 - TSA_EXISTING_PUBLIC_KEY = < the public key of the TSA, usually in `/concourse-keys/tsa_host_key.pub`
 - WORKER_EXISTING_PRIVATE_KEY = the private key of an existing worker (shared key) or an key you deployed into authorized_workers on the tsa

And set this on the worker itself

 - CONCOURSE_TSA_HOST
 - CONCOURSE_TSA_PORT ( should be 2222)
To test this locally you need to 

```bash

docker-composer up

# now extract the /concourse-keys/worker_key from the worker container and
# replace all newlines with an \n to make it a oneliner ( dotenv does not support multiline yet )
# put the value into ..standalone-worker-env WORKER_EXISTING_PRIVATE_KEY
# also extract /concourse-keys/tsa_host_key.pub (its already a one liner)
# put the value into ..standalone-worker-env TSA_EXISTING_PUBLIC_KEY
# adjust CONCOURSE_TSA_HOST if you have a different lo0 ip

docker-compose -f docker-compose-worker-standalone.yml up
```
    
## Examples

### Vault

See the `run_3_vault_test.sh` script to see how consul con be setup and started with a vault based pipeline 
`example/vaults-based`
