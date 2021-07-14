#!/bin/bash

resourceGroupName=spark-azure-func-secretless-yes
location=eastus
deploymentLabel=bicep-deploy-"$(date +'%Y%m%d_%H%M%S')"

if [ $(az group exists --name $resourceGroupName) = false ]; then
    az group create --name $resourceGroupName --location $location
else
    echo "Resource group '$resourceGroupName' already exists, skipping . . ."
fi

# Deploy the Bicep file and save the output.
az deployment group create --name $deploymentLabel --resource-group $resourceGroupName --template-file ./src/bicep/main.secretless.bicep > output.json

# Get the output resources.
outputResources=$(jq -r '.properties.outputResources' output.json)

# Find the name of the created Azure Function.
for resource in $outputResources; do
    if [[ $resource == *'Microsoft.Web/sites'* && $resource != *'networkConfig/virtualNetwork'* ]]; then
        functionResource=${resource%\"*}
        functionName=${functionResource##*/}
        echo "Function deployed - '$functionName'."
    fi

    if [[ $resource == *'Microsoft.Storage/storageAccounts'* && $resource != *'blobServices'* && $resource != *'roleAssignments'* && $resource != *'queueServices'* ]]; then
        storageResource=${resource%\"*}
        storageAccountName=${storageResource##*/}
        echo "Storage deployed - '$storageAccountName'."
    fi
done
