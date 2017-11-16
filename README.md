## start

This will start a concourse server right up, including vault and vault preconfigured

    docker-compose up
    
    
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
    