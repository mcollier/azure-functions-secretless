#!/bin/bash

FUNCTIONNAME=$1

# Change to the directory where the Azure Function app resides.
cd ./src/function

# Publish the function app.
echo "Attempting to publish to $FUNCTIONNAME."
func azure functionapp publish $FUNCTIONNAME