#!/bin/zsh

# Required
resourceGroupName=""
acrName=""
spName=""
kvName=""

# Optional
location=""

# Parse arguments
while getopts ":g:r:l:p:k:" option; do
  case $option in
    g) resourceGroupName=${OPTARG};;
    r) acrName=${OPTARG};;
    l) location=${OPTARG};;
    p) spName=${OPTARG};;
    k) kvName=${OPTARG};;
  esac
done

# Validate required parameters
if [ -z $resourceGroupName ] || [ -z $acrName ] || [ -k $kvName ]; then
  echo "Usage: $0 -g <resourceGroup>  -r <acrName>  -k <kvName>  [-l <location>] [-p <spName>]" >&2
  exit 1
fi

# Set defaults 
location=${location:-"australiasoutheast"}
spName=${spName:-"$resourceGroupName-sp"}

# Set subscriptionId from current context
subscriptionId=$(az account show --query id -o tsv)

# Create resource group
az group create --name $resourceGroupName --location $location 

# Create container registry
az acr create --resource-group $resourceGroupName --name $acrName --sku Basic

# Create service principal 
echo "================ Copy ClientId and ClientSecret from json credentials below ================="
spCredential=$(az ad sp create-for-rbac --name $spName --role Contributor --scopes /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName --json-auth)
echo $spCredential
echo "======================================================================================"


echo "Setup key vault and assign current user contributor role"

# Get currenly logged in user's object ID
currentUserObjectId=$(az ad signed-in-user show --query id -o tsv)
echo "Note, current user's object ID: $currentUserObjectId"

# Create key vault
az keyvault create --name $kvName --resource-group $resourceGroupName

# Get key vault ID 
kvId=$(az keyvault show --name $kvName --query id -o tsv)

# Assign current user as contributor 
az role assignment create --assignee $currentUserObjectId --role "Contributor" --scope $kvId


