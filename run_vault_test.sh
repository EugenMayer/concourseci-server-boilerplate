fly -t lite login -c http://127.0.0.1:8080 -u concourse -p changeme || (echo "please login yourself since http://127.0.0.1:8080 is not the right docker-machine ip for you" && exit 1)

echo "inserting value"
docker-compose exec config bash -l -c 'source /vault/server/init_vars && vault write secret/concourse/main/main/myvalue value=foo'

# deploy the pipline
fly sp -t lite configure -c examples/vault-based/pipeline.yml  -p main -n
# unpause the pipeline
fly -t lite unpause-pipeline -p main
# trigger the job and watch the logs
fly -t lite trigger-job -j main/vault-test -w