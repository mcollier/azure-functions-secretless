@description('Location for all resources except Application Insights.')
param location string = resourceGroup().location

@description('Location for Application Insights.')
param appInsightsLocation string = resourceGroup().location

@description('The language worker runtime to load in the function app.')
@allowed([
  'node'
  'dotnet'
  'java'
])
param functionRuntime string = 'dotnet'

@description('The name of the function app that you wish to create.')
param functionAppName string = 'func-${uniqueString(resourceGroup().id)}'

param hostingPlanName string = 'plan-${uniqueString(resourceGroup().id)}'

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

var storageAccountName = 'st${uniqueString(resourceGroup().id)}'
var storageQueueName = 'orders'
var appInsightsName = 'appi-${uniqueString(resourceGroup().id)}'
var eventHubNamespaceName = 'evhns-${uniqueString(resourceGroup().id)}'
var eventHubName = 'items'
var packageContainerName = 'packages'

// -- SECRETLESS -- //
// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var storageBlobContributorRoleDefinitionId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var storageQueueContributorRoleDefinitionId = '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
var eventHubsDataReceiverRoleDefinitionId = 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource storageQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-04-01' = {
  name: '${storageAccount.name}/default/${storageQueueName}'
}

// -- SECRETLESS -- //
// Create a folder for running Azure Functions packages.
resource packageBlobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccount.name}/default/${packageContainerName}'
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-01-01-preview' = {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-01-01-preview' = {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    messageRetentionInDays: 7
    partitionCount: 32
  }
}

resource appInsights 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: appInsightsName
  location: appInsightsLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource serverFarm 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
  kind: 'elastic'
  properties: {
    maximumElasticWorkerCount: 20
  }
}

resource function 'Microsoft.Web/sites@2020-06-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'

  // -- SECRETLESS -- //
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    serverFarmId: serverFarm.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsights.properties.InstrumentationKey}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionRuntime
        }
        {
          name: 'QueueName'
          value: storageQueueName
        }
        {
          name: 'EventHubName'
          value: eventHubName
        }

        // -- SECRETLESS -- //
        {
          name: 'StorageQueueConnection__accountName'
          value: storageAccount.name
        }
        {
          name: 'StorageQueueConnection__credential' //NOTE: Temporary issue; Azure-hosted only!
          value: 'managedIdentity'
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        {
          name: 'EventHubConnection__fullyQualifiedNamespace'
          value: '${eventHubNamespace.name}.servicebus.windows.net'
        }
        {
          name: 'EventHubConnection__credential' //NOTE: Temporary issue; Azure-hosted only!
          value: 'managedIdentity'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: 'https://${storageAccount.name}.blob.${environment().suffixes.storage}/${packageContainerName}/publish.zip'
        }
      ]
    }
  }
}

// -- SECRETLESS -- //
// Storage Blob Data Contributor
resource funcBlobRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(storageBlobContributorRoleDefinitionId, resourceGroup().id)
  scope: storageAccount
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${storageBlobContributorRoleDefinitionId}'
    principalId: function.identity.principalId
  }
}

// Storage Queue Data Contributor
resource funcQueueRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(storageQueueContributorRoleDefinitionId, resourceGroup().id)
  scope: storageAccount
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${storageQueueContributorRoleDefinitionId}'
    principalId: function.identity.principalId
  }
}

// Event Hubs Data Receiver
resource funcEventHubRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(eventHubsDataReceiverRoleDefinitionId, resourceGroup().id)
  scope: eventHubNamespace
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${eventHubsDataReceiverRoleDefinitionId}'
    principalId: function.identity.principalId
  }
}
