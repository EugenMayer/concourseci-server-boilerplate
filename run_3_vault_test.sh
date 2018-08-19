#!/bin/bash

set -e

flycli=~/Downloads/fly

echo "inserting VAULT value"
docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault write secret/concourse/main/main/firstvalue value=foo'
docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault write secret/concourse/main/lower_level_secondvalue value=bar'
docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault write secret/concourse/main/obj user=me password=mypasword'
# this one will not be readable, concourse does not support nested values.
docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault write secret/concourse/nested/value value=foobar'


# deploy the pipline
$flycli sp -t test_main configure -c examples/vault-based/pipeline.yml -p vaultpipeline -n
# unpause the pipeline
$flycli -t test_main unpause-pipeline -p vaultpipeline
# trigger the job and watch the logs
$flycli -t test_main trigger-job -j vaultpipeline/vault-test -w