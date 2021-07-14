#!/bin/bash

resourceGroupName=spark-azure-func-secretless-no
location=eastus
deploymentLabel=bicep-deploy-"$(date +'%Y%m%d_%H%M%S')"

if [ $(az group exists --name $resourceGroupName) = false ]; then
    az group create --name $resourceGroupName --location $location
else
    echo "Resource group '$resourceGroupName' already exists, skipping . . ."
fi

# Deploy the Bicep file and save the output.
az deployment group create --name $deploymentLabel --resource-group $resourceGroupName --template-file ./src/bicep/main.bicep > output.json

# Get the output resources.
outputResources=$(jq -r '.properties.outputResources' output.json)

# Find the name of the created Azure Function.
for resource in $outputResources; do
    if [[ $resource == *'Microsoft.Web/sites'* && $resource != *'networkConfig/virtualNetwork'* ]]; then
        functionResource=${resource%\"*}
        functionName=${functionResource##*/}
        echo $functionName
    fi
done
