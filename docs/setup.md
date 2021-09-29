# Setup and run MLOps pipelines from this repo

## Step 1: Fork this repo
You can [fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo#forking-a-repository) from github.com.

## Step 2: Set the required environment variables for the pipelines to work
In Github action you need to use secrets to set environment variables. These variables will be used in the various pipelines.
In your forked repository, create the following [repository level `secrets`](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository) :

Secret | Description/Instructions |
|------|------------|
|SUBSCRIPTION_ID | Your azure subscription id |
|RESOURCE_GROUP | Resource group where your resources will be created. Make sure this already exists |
| AML_WORKSPACE | Name of your azure ml workspace. Make sure this already exists. |
| LOCATION | Azure region for your Azure ML workspace  e.g. eastus |
| ENDPOINT_NAME | Name of the managed online endpoint that will be created part of the pipelines. This needs to be a unique value across azure region level. For e.g my-endpt-<XXXXX>, where XXXXX is a random number. |
| ENDPOINT_TOKEN | Put any dummy value here. We get endpoint credentials into the env variable inside one of the scripts. Defining this as secret ensures it is not accidentally printed in the logs |

## Step 3: Create Service Principal and add it to the Secrets

A service principal (SP) is needed inorder for your github actions pipelines to create and modify resources. Prerequsite to create a is that you have either `Owner` or `User access administrator` role at the subscription level. If you do not have it, ask your admin to execute the steps.

Create a SP and add it to the repository `secrets` named `AZURE_CREDENTIALS` by following instructions [here](https://github.com/marketplace/actions/azure-login#configure-deployment-credentials). Ignore the option to create SP for webapp, and just do it for `resource group`.

## Step 4: Setup your workspace

[Run](https://docs.github.com/en/actions/managing-workflow-runs/manually-running-a-workflow) the `Setup` github action pipeline to finish the setup.
This will create the following resources:
1. Azure ML workspace, if it does not already exists
2. Log analytics workspace (used for managed online endpoints)
3. Training cpu-cluster
4. A sample dataset for training

## [Optional] Step 5: Create environments in github (aka release gates)

This will add 5 delays after rollout of incremental traffic inorder to validate the metrics for that time period.

[Create the following Environments](https://docs.github.com/en/actions/deployment/environments#creating-an-environment):
1. rollout_50pct_traffic_env
1. rollout_100pct_traffic_env
1. delete_old_prod_env

In all the above environments, configure delay timer as `5` mins.

__Known issue:__ The delay specified in the Environment protection rules does not seem to be honoured - let me know if you figure this out (create an issue in this repo).

## Get started!
Now you are all set! Go to the [getting started](getting-started.md) to try out the mlops pipelines

## Delete resources
Once you are done, [delete the resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#delete-resource-groups) (or the azure ml workspace and other resources created from the pipelines) inorder to avoid any charges.

