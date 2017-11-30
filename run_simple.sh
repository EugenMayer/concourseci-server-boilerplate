fly -t lite login -c http://127.0.0.1:8080 -u concourse -p changeme || (echo "please login yourself since http://127.0.0.1:8080 is not the right docker-machine ip for you" && exit 1)

# deploy the pipline
fly sp -t lite configure -c examples/simple/pipeline.yml  -p main -n
# unpause the pipeline
fly -t lite unpause-pipeline -p main
