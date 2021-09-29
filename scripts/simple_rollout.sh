# Generate name for new release candidate (RC) deployment.
export RC_DEPLOYMENT_NAME=deploy-`echo $RANDOM`

#path to endpoint and deployment yaml
ENDPOINT_FILE=endpoint/endpoint.yml
DEPLOYMENT_FILE=endpoint/deployment.yml

# create endpoint if it does not exist
ENDPOINT_EXISTS=$(az ml online-endpoint list -o tsv --query "[?name=='$ENDPOINT_NAME'][name]" |  wc -l)
if [[ ENDPOINT_EXISTS -ne 1 ]]; then
    az ml online-endpoint create -n $ENDPOINT_NAME -f $ENDPOINT_FILE      
else
    echo "endpoint exists"
fi

# deploy the latest version of the model as a new deployment
LATEST_MODEL_VERSION=$(az ml model show -n risk-model -o tsv --query version)
MODEL_REF=azureml:risk-model:$LATEST_MODEL_VERSION
echo $MODEL_REF
az ml online-deployment create --name $RC_DEPLOYMENT_NAME --endpoint $ENDPOINT_NAME -f $DEPLOYMENT_FILE --set model=$MODEL_REF

# if PROD does not exist, mark this as prod and exit
PROD_DEPLOYMENT=$(az ml online-endpoint show -n $ENDPOINT_NAME -o tsv --query "tags.PROD_DEPLOYMENT")
if [[ -z "$PROD_DEPLOYMENT" ]]; then
    # tag the current deployment as prod and set traffic to 100%
    az ml online-endpoint update --name $ENDPOINT_NAME --traffic "$RC_DEPLOYMENT_NAME=100" --set tags.PROD_DEPLOYMENT=$RC_DEPLOYMENT_NAME
    # exit. If the script is run again it will now create new deployment and perform safe rollout
    echo "Initial PROD deployment created. Rerun script for safe rollout of new deployment. Exiting."
    exit 0
fi

# sanity test deployment is working with zero percent traffic
az ml online-endpoint invoke -n $ENDPOINT_NAME --deployment $RC_DEPLOYMENT_NAME --request-file endpoint/sample-request.json

# rollout 10% traffic to RC (release candidate)
az ml online-endpoint update -n $ENDPOINT_NAME --traffic "$PROD_DEPLOYMENT=90 $RC_DEPLOYMENT_NAME=10"        

# rollout 50% traffic to RC
az ml online-endpoint update -n $ENDPOINT_NAME --traffic "$PROD_DEPLOYMENT=50 $RC_DEPLOYMENT_NAME=50"

# (a) rollout 100% traffic to RC (b) tag PROD as OLD_PROD (c) tag new deployment(RC) as prod
az ml online-endpoint update -n $ENDPOINT_NAME --traffic "$RC_DEPLOYMENT_NAME=100" --set tags.PROD_DEPLOYMENT=$RC_DEPLOYMENT_NAME tags.OLD_PROD_DEPLOYMENT=$PROD_DEPLOYMENT
OLD_PROD_DEPLOYMENT=$PROD_DEPLOYMENT
PROD_DEPLOYMENT=$RC_DEPLOYMENT_NAME

# delete OLD_PROD after removing the OLD_PROD tag
az ml online-endpoint update -n $ENDPOINT_NAME --remove tags.OLD_PROD_DEPLOYMENT
az ml online-deployment delete --endpoint $ENDPOINT_NAME --name $OLD_PROD_DEPLOYMENT --yes --no-wait