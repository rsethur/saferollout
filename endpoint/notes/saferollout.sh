#Step 1: validation and day1 scenarios
#Step 1a: If endpoint does not exist, create
export ENDPOINT_EXISTS=$(az ml endpoint list -o tsv --query "[?name=='$ENDPOINT_NAME'][name]" |  wc -l)
if [[ ENDPOINT_EXISTS -ne 1 ]]; then
  az ml endpoint create -n $ENDPOINT_NAME -f $ENDPOINT_FILE
else
  echo "endpoint $ENDPOINT_NAME exists"
fi

#Step 1b: If deployment with same name exists then quit
export RC_DEPLOYMENT_EXISTS=$(az ml endpoint show -n $ENDPOINT_NAME -o tsv --query "deployments[?name == '$RC_DEPLOYMENT'].name" |  wc -l)
if [[ RC_DEPLOYMENT_EXISTS -eq 1 ]]; then
 echo "deployment with name $RC_DEPLOYMENT already exists. Exiting."
 exit 1
fi

# Step 1c:  If prod does not exist, create the RC as prod. Else If PROD exists validate if it has 100%.
# get number of deployments
export NUM_DEPLOYMENTS=$(az ml endpoint show -n $ENDPOINT_NAME -o tsv --query 'deployments | length(@)' | tr -d "\r")
# Get the name of prod deployment
export PROD_DEPLOYMENT=$(az ml endpoint show -n $ENDPOINT_NAME -o tsv --query "tags.PROD_DEPLOYMENT")
if [[ -z "$PROD_DEPLOYMENT" ]]; then
  export PROD_DEPLOYMENT=$RC_DEPLOYMENT  
  az ml endpoint update -n $ENDPOINT_NAME --deployment $PROD_DEPLOYMENT --deployment-file $DEPLOYMENT_FILE --set deployments[$NUM_DEPLOYMENTS].model=$RC_MODEL --traffic $PROD_DEPLOYMENT:100 --set tags.PROD_DEPLOYMENT=$PROD_DEPLOYMENT
  exit 0 
else # validate if PROD  has 100%.
  export PROD_TRAFFIC=$(az ml endpoint show -n $ENDPOINT_NAME -o tsv --query traffic.$PROD_DEPLOYMENT)
  if [[ $PROD_TRAFFIC -ne '100' ]]; then echo "Error: traffic to prod deployment needs to be 100%"; exit 1; fi   
fi

#Step 2: Create RC deployment
az ml endpoint update -n $ENDPOINT_NAME --deployment $RC_DEPLOYMENT --deployment-file $DEPLOYMENT_FILE --set deployments[$NUM_DEPLOYMENTS].model=$RC_MODEL --traffic "$PROD_DEPLOYMENT:100,$RC_DEPLOYMENT:0"
 
#Step 3: Divert 10% traffic
az ml endpoint update -n $ENDPOINT_NAME --traffic $PROD_DEPLOYMENT:90,$RC_DEPLOYMENT:10

# run some tests
# TODO - insert test script here

#Step 4: Rollout 100% traffic to RC & mark RC as PROD
az ml endpoint update -n $ENDPOINT_NAME  --traffic $PROD_DEPLOYMENT:0,$RC_DEPLOYMENT:100 --set tags.PROD_DEPLOYMENT=$RC_DEPLOYMENT
export OLD_PROD_DEPLOYMENT=$PROD_DEPLOYMENT
export PROD_DEPLOYMENT=$RC_DEPLOYMENT

# Step 5: Delete OLD_PROD_DEPLOYMENT deployment
az ml endpoint delete -n $ENDPOINT_NAME --deployment $OLD_PROD_DEPLOYMENT --yes #--no-wait