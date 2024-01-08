
#!/bin/zsh

# Required
resourceGroupName=""
acrName=""
spClientId=""
spClientSecret=""
kvName=""

# Optional
location=""

# Parse arguments
while getopts ":g:r:l:c:p:k:" option; do
  case $option in
    g) resourceGroupName=${OPTARG};;
    r) acrName=${OPTARG};;
    l) location=${OPTARG};;
    c) spClientId=${OPTARG};;
    p) spClientSecret=${OPTARG};;
    k) kvName=${OPTARG};;
  esac
done

# Validate required parameters
if [ -z $resourceGroupName ] || [ -z $acrName ] || [ -z $spClientId ] || [ -z $spClientSecret ]; then
  echo "Usage: $0 -g <resourceGroup> -r <acrName> -c <spClientId> -p <spClientSecret> -k [<keyVaultName>] [-l <location>]" >&2
  exit 1
fi

# Set default location 
location=${location:-"australiasoutheast"}

# Get the Service Principle ID corresponding to user with provided Client ID
servicePrincipalId=$(az ad sp show --id $spClientId --query id -o tsv)

echo "Using Service Principal Id: "$servicePrincipalId

# Deploy the Bicep template
az deployment group create --resource-group $resourceGroupName --template-file ../bicep/main.bicep --parameters location=$location containerRegistry=$acrName".azurecr.io" servicePrincipalClientId=$spClientId servicePrincipalId=$servicePrincipalId servicePrincipalPassword=$spClientSecret keyVaultName=$kvName
