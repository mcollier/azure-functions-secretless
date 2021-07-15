#!/bin/bash

STORAGE_ACCOUNT_NAME=$1

echo "Publishing project . . ."
dotnet publish ./src/function --configuration Release

echo "Zipping project . .  ."
cd ./src/function/bin/Release/netcoreapp3.1/publish/
zip -r publish.zip .

echo "Uploading package . . ."
az storage blob upload --account-name $STORAGE_ACCOUNT_NAME --container-name packages --file publish.zip --name publish.zip --auth-mode key