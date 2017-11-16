
fly -t lite login -c http://172.31.31.254:8080 -u concourse -p changeme

echo "inserting value"
docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault write secret/concourse/main/main/myvalue value=foo'

# deploy the pipline
fly sp -t lite configure -c examples/vault-based/pipeline.yml  -p main -n
# unpause the pipeline
fly -t lite unpause-pipeline -p main
# trigger the job and watch the logs
fly -t lite trigger-job -j main/vault-test -w