# Getting started

1. Complete the [setup](setup.md)
1. Run the `train` github action. This job will train the model based on the dataset and register it. This will automatically trigger the `auto-saferollout` github action. In the first run it will create the endpoint and first version of the deployment
1. Run the above action again. This time it creates new deployment and gradually rolls out traffic to it. At each step it runs validaton by checking if metrics are within threshold.
1. You can keep running with the `train` or the `auto-saferollout` actions to rollout new versions. You can also configure this to run on a schedule.

## Understanding the scripts
If you did not already, checkout [output of the above actions](../../../actions): you will see the pipleine graph with various steps.
1. Prerequsite: Make sure you understand basic of managed online endpoints: [concept](https://docs.microsoft.com/en-us/azure/machine-learning/concept-endpoints), [simple deployment flow](http://docs.microsoft.com/en-us/azure/machine-learning/how-to-deploy-managed-online-endpoints) and [safe rollout](https://docs.microsoft.com/en-us/azure/machine-learning/how-to-safely-rollout-managed-endpoints)
1. Understand the [simple shell script based rollout](../scripts/simple_rollout.sh)
1. Good to understand the [validate-metrics github action](https://github.com/rsethur/validate-metrics) that is used here
1. Understand the [auto saferollout github action](../.github/workflows/auto_saferollout.yml)
