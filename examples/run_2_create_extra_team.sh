#!/bin/bash

set -e

EXTERNAL_URL=localhost
FLY=${FLYBIN:-fly}

echo "creating team extrateam under login target test_extrateam"
echo "this test is kinda complicated due to the logout first, login again thing ( JWT cache ) - maybe skip it"

# be sure we are still logged in the main teams
$FLY -t test_main status > /dev/null 2>&1 || $FLY -t test_main login -c http://$EXTERNAL_URL -b --team-name=main || (echo "please login yourself since http://${EXTERNAL_URL} is not the right docker-machine ip for you" && exit 1)


# create the extra team using the main target
yes |  $FLY -t test_main set-team --team-name=extrateam --ldap-user=included1


# It seems like the team-create above is not applied onto users which are alread logged in
# thus if we are still logged in from run_1_login_deploy.sh -  included1 will yet not be not part of the extrateam group until
# the user logs out and logs in again. Most probably since the roles / groups are part of the JWT token which is still valid
# just a concourse permission cache bug
# fly -t test_main logout || true
# create a login for the new team
$FLY -t test_extrateam status > /dev/null 2>&1  || $FLY -t test_extrateam login -c http://${EXTERNAL_URL} -b --team-name=extrateam || \
 (echo "The login failed, most probably due to the JWT cache. Please logout from concourse in your browser and the run this script again" && exit 1)


# deploy the pipline
$FLY sp -t test_extrateam configure -c simple/pipeline.yml -p mypipeline -n
# unpause the pipeline
$FLY -t test_extrateam unpause-pipeline -p mypipeline
