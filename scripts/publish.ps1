dotnet publish ./src/function --configuration Release --output ./src/function/publish

Compress-Archive -Path .\src\function\publish\* -DestinationPath .\src\function\publish.zip -Force

azcopy copy ".\src\function\publish.zip" "https://stloeqmyrc4isv6.blob.core.windows.net/packages/publish.zip"