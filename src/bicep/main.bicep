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
var appInsightsName = 'appi-${uniqueString(resourceGroup().id)}'
var storageQueueName = 'widgets'

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

resource packageBlobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccount.name}/default/packages'
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
        // {
        //   name: 'AzureWebJobsStorage'
        //   value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listkeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        // }
        // {
        //   name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
        //   value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listkeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};'
        // }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionRuntime
        }
        {
          name: 'InputQueueName'
          value: storageQueueName
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        {
          name: 'QueueConnection__accountName'
          value: storageAccount.name
        }
        {
          name: 'QueueConnection__credential'
          value: 'managedIdentity'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: 'https://stloeqmyrc4isv6.blob.core.windows.net/packages/publish.zip'
        }
      ]
    }
  }
}

// Storage Blob Data Contributor
resource funcBlobRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: 'functionBlobRoleAssignment'
  scope: storageAccount
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalId: function.identity.principalId
  }
}

// Storage Queue Data Contributor
resource funcQueueRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: 'functionQueueRoleAssignment'
  scope: storageAccount
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/974c5e8b-45b9-4653-ba55-5f855dd0fb88'
    principalId: function.identity.principalId
  }
}
