## Install
http://concourse.ci/docker-repository.html

now install the cli

    brew cask install fly

now login with the cli against our local server

    fly -t lite login -c http://172.31.31.254:8080 
    user: concourse
    pw: changeme
    # update fly

update fly    
    
    fly -t lite sync
    
    
## create a pipeline    

push a pipeline to the main team / pipeline from `i/pipline.yml`

    fly sp -t lite configure -c ci/pipline.yml -p main --load-vars-from ../credentials.yml -n
    
    
## intercept into a broken / running container

    fly -t lite intercept -j <pipelinename>/<jobname>
    
so for example, assuming we have a job in pipeline `main` named `builder-image-build`

    fly -t lite intercept -j main/builder-image-build
     
