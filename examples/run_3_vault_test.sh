#!/bin/bash

set -e
FLY=${FLYBIN:-fly}

echo "inserting VAULT value"
docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault kv put secret/concourse/main/firstvalue value=foo'
docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault kv put secret/concourse/main/lower_level_secondvalue value=bar'
docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault kv put secret/concourse/main/obj user=me password=mypasword'


# deploy the pipeline
$FLY sp -t test_main configure -c vault-based/pipeline.yml -p vaultpipeline -n
# unpause the pipeline
$FLY -t test_main unpause-pipeline -p vaultpipeline
# trigger the job and watch the logs
$FLY -t test_main trigger-job -j vaultpipeline/vault-test -w