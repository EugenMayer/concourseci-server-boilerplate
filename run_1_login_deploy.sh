#!/bin/bash

set -e
flycli=~/Downloads/fly

echo "logging in into team main under target test_main"

$flycli -t test_main login -c http://127.0.0.1:8080 -b --team-name=main || (echo "please login yourself since http://127.0.0.1:8080 is not the right docker-machine ip for you" && exit 1)

# deploy the pipline
$flycli sp -t test_main configure -c examples/simple/pipeline.yml -p mypipeline -n
# unpause the pipeline
$flycli -t test_main unpause-pipeline -p mypipeline
