#!/bin/bash

set -e

echo "creating team extrateam under login target test_extrateam"

flycli=~/Downloads/fly

# create the extra team using the main target
$flycli -t test_main set-team --team-name=extrateam --ldap-user=included1

# create a login for the new team
$flycli -t test_extrateam login -c http://127.0.0.1:8080 -b --team-name=extrateam || (echo "please login yourself since http://127.0.0.1:8080 is not the right docker-machine ip for you" && exit 1)


# deploy the pipline
$flycli sp -t test_extrateam configure -c examples/simple/pipeline.yml -p mypipeline -n
# unpause the pipeline
$flycli -t test_extrateam unpause-pipeline -p mypipeline
