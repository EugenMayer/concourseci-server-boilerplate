## start
Before you go, please adjust the actual `docker-machine ip` in `.env`

    CONCOURSE_EXTERNAL_URL=
    
If you have docker-for-mac/windows, you need to create a `iface alias` on `lo0` , [see this](https://gist.github.com/EugenMayer/a0d0d603a769aa61c8b462b176dbdba7), and use that ip here ( as i did ), or your
worker connections wont work.

This will start a concourse server right up, including vault and vault preconfigured

    docker-compose up

**Hint:** If you happen to notice, why we do use `eugenmayer/concourse-worker-solid:3.6.0` instead of `concourse/concourse` as worker, please see this [docs](https://github.com/EugenMayer/docker-image-concourseci-worker-solid)    
## setup 

now install the cli

    brew cask install fly

now login with the cli against our local server

    fly -t lite login -c http://172.31.31.254:8080 -u concourse -p changeme
    # update fly

update fly    
    
    fly -t lite sync
    
Adjustments can be done by editing the .env file    


## access the webui
You can access the webui with the user concourse` and password `changeme`

    http://localhost:8080
            
## create a pipeline    

push a pipeline to the main team / pipeline from `ci/pipline.yml`

    fly sp -t lite configure -c ci/pipline.yml -p main --load-vars-from ../credentials.yml -n   
    
## intercept into a broken / running container

    fly -t lite intercept -j <pipelinename>/<jobname>
    
so for example, assuming we have a job in pipeline `main` named `builder-image-build`

    fly -t lite intercept -j main/builder-image-build
     
## vault access and setting values

To adjust your vault or putting value into it, you should use the configurator container, which has the ability to talk to it
and set new values. Its pretty easy, just do

connect into the container   

    docker-compose exec config bash

load credentials and server config
    
    source /vault/server/init_vars

set a value of your desire
    
    vault write secret/concourse/test value=test
    
### testing client access

since the above is all done using the server token, you can try the client token too

    docker-compose exec config bash
    
    export VAULT_CLIENT_CERT=/vault/concourse/cert.pem 
    export VAULT_CLIENT_KEY=/vault/concourse/key.pem 
    export VAULT_ADDR=https://vault:8200
    export VAULT_CACERT=/vault/concourse/server.crt
    
    vault auth -method=cert
    vault read secret/concourse/main/main/myvalue

## Running the standalone worker

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

### vault

start the stack and login

    docker-compose up
    fly -t lite login -c http://172.31.31.254:8080 -u concourse -p changeme

create our test-value in the vault    

    docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault write secret/concourse/main/main/myvalue value=foo'

add the pipeline to our concourse
    
    # deploy the pipline
    fly sp -t lite configure -c examples/vault-based/pipeline.yml  -p main -n
    # unpause the pipeline    
    fly -t lite unpause-pipeline -p main
    # trigger the job and watch the logs
    fly -t lite trigger-job -j main/test-vault -w
    
You should see a echo foo` in the logs    