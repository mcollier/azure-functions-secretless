#!/bin/bash

RESOURCE_GROUP_NAME=spark-azure-func-secretless-yes
STORAGE_ACCOUNT_NAME=stqtk5kkh5hezug
EVENT_HUB_NAMESPACE_NAME=evhns-qtk5kkh5hezug
USER_PRINCIPAL_NAME=mcollier@microsoft.com

# assigneeId=$(az ad user list --upn $USER_PRINCIPAL_NAME --query []."objectId" -o tsv)

storageQueueRoleDefinitionId=$(az role definition list --name "Storage Queue Data Contributor" --query []."name" -o tsv)
storageBlobRoleDefinitionId=$(az role definition list --name "Storage Blob Data Contributor" --query []."name" -o tsv)
eventHubRoleDefinitionId=$(az role definition list --name "Azure Event Hubs Data Receiver" --query []."name" -o tsv)

storageAccountResourceId=$(az storage account show --name $STORAGE_ACCOUNT_NAME -g $RESOURCE_GROUP_NAME --query "id" -o tsv)
eventHubResourceId=$(az eventhubs namespace show --name $EVENT_HUB_NAMESPACE_NAME -g $RESOURCE_GROUP_NAME --query "id" -o tsv)

az role assignment create --assignee $USER_PRINCIPAL_NAME --role $storageQueueRoleDefinitionId --scope $storageAccountResourceId
az role assignment create --assignee $USER_PRINCIPAL_NAME --role $storageBlobRoleDefinitionId --scope $storageAccountResourceId
az role assignment create --assignee $USER_PRINCIPAL_NAME --role $eventHubRoleDefinitionId --scope $eventHubResourceId