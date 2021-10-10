#!/bin/bash

set -e

EXTERNAL_URL=localhost
FLY=${FLYBIN:-fly}

echo "logging in into team main under target test_main"

# we have to logout prio otherwise if we logged into the test server back in time the login process below will succeed
# but it will actually not work.. just another bug in concourse
# fly -t test_main logout || true
$FLY -t test_main status > /dev/null 2>&1 || fly -t test_main login -c http://$EXTERNAL_URL:8080 -b --team-name=main || (echo "please login yourself since http://${EXTERNAL_URL}:8080 is not the right docker-machine ip for you" && exit 1)

# deploy the pipline
$FLY sp -t test_main configure -c simple/pipeline.yml -p mypipeline -n
# unpause the pipeline
$FLY -t test_main unpause-pipeline -p mypipeline
