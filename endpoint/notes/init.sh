#!/bin/sh
# endpoint name
export ENDPOINT_NAME='my-endpt1'
# endpoint file
export ENDPOINT_FILE=endpoint/endpoint.yml
# name of new deployment - can be runid etc
export RC_DEPLOYMENT='dv2'
# deployment file
export DEPLOYMENT_FILE=endpoint/deployment.yml
# new model name & version. ideally this can just be a version - and replaced using sed or something (so changes are in git)
export RC_MODEL=azureml:risk-model:1