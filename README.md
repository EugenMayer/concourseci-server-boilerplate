## Install
http://concourse.ci/docker-repository.html

now install the cli

    brew cask install fly

now login with the cli against our local server

    fly -t lite login -c http://172.31.31.254:8080 
    user: concourse
    pw: changeme
    # update fly
    fly -t lite sync
