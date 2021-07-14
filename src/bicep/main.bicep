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
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listkeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listkeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};'
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
        {
          name: 'EventHubConnection'
          value: listKeys(resourceId('Microsoft.EventHub/namespaces/authorizationRules', eventHubNamespaceName, 'RootManageSharedAccessKey'), '2021-01-01-preview').primaryConnectionString
        }
      ]
    }
  }
}
