#!/bin/bash

cd ./src/function

dotnet add package Microsoft.Azure.WebJobs.Extensions.Storage --version 5.0.0-beta.5
dotnet add package Microsoft.Azure.WebJobs.Extensions.EventHubs --version 5.0.0-beta.7