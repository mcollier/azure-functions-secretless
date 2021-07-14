# Creating a secretless Azure Function

## Convert to Secretless

1. Remove WEBSITE_CONTENTAZUREFILECONNECTIONSTRING and WEBSITE_CONTENTSHARE (shouldn't be there anyways).
1. May notice "Storage is not configured properly. Function scaling will be limited. Click to learn more." error.  This is to be expected since Azure Files was removed.
1. Enable managed identity (system assigned).
1. Add role assignments
    1. Storage Blob Data Contributor
    1. Storage Queue Data Contributor
1. Create zip
    1. dotnet build
    1. create zip
1. Upload zip to Azure storage blob.  Create a "packages" container.
1. Get URL of blob.
1. Add blob url to WEBSITE_RUN_FROM_PACKAGE
1. Change `AzureWebJobsStorage` to `AzureWebJobsStorage_accountName` with value of the storage account name (no keys).
1. Optional - add key valut reference
1. Add new storage extension (5.x).
1. Create new `QueueConnection_accountName` app setting, with value of the storage account name.
1. Create new `QueueConnection_credential` app setting, with value of `managedIdentity`.
    - Future update will remove the need for this setting!
1. Test locally. Need to be signed into Azure CLI.
1. Publish app.
1. Test in Azure.