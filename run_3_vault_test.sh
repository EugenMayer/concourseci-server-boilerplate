#!/bin/bash

set -e


echo "inserting VAULT value"
docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault kv put secret/concourse/main/firstvalue value=foo'
docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault kv put secret/concourse/main/lower_level_secondvalue value=bar'
docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault kv put secret/concourse/main/obj user=me password=mypasword'


# deploy the pipeline
fly sp -t test_main configure -c examples/vault-based/pipeline.yml -p vaultpipeline -n
# unpause the pipeline
fly -t test_main unpause-pipeline -p vaultpipeline
# trigger the job and watch the logs
fly -t test_main trigger-job -j vaultpipeline/vault-test -w