#!/bin/bash

resourceGroupName=spark-azure-func-secretless
location=northcentralus
deploymentLabel=bicep-deploy-"$(date +'%Y%m%d_%H%M%S')"

if [ $(az group exists --name $resourceGroupName) = false ]; then
    az group create --name $resourceGroupName --location $location
    # az deployment sub create --location $location --template-file ./infrastructure/bicep/resource-group.bicep --parameters \
    #     location=$location \
    #     resourceGroupName=$resourceGroupName
else
    echo "Resource group '$resourceGroupName' already exists, skipping . . ."
fi

az deployment group create --name $deploymentLabel --resource-group $resourceGroupName --template-file ./infrastructure/bicep/main.bicep