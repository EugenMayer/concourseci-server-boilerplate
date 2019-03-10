#!/bin/bash

set -e

echo "logging in into team main under target test_main"

# we have to logout prio otherwise if we logged into the test server back in time the login process below will succeed
# but it will actually not work.. just another bug in concourse
# fly -t test_main logout || true
fly -t test_main status > /dev/null 2>&1 || fly -t test_main login -c http://127.0.0.1:8080 -b --team-name=main || (echo "please login yourself since http://127.0.0.1:8080 is not the right docker-machine ip for you" && exit 1)

# deploy the pipline
fly sp -t test_main configure -c examples/simple/pipeline.yml -p mypipeline -n
# unpause the pipeline
fly -t test_main unpause-pipeline -p mypipeline
