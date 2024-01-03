#!/bin/zsh

# Required
resourceGroupName=""
acrName=""
spName=""

# Optional
location=""

# Parse arguments
while getopts ":g:r:l:p:" option; do
  case $option in
    g) resourceGroupName=${OPTARG};;
    r) acrName=${OPTARG};;
    l) location=${OPTARG};;
    p) spName=${OPTARG};;
  esac
done

# Validate required parameters
if [ -z $resourceGroupName ] || [ -z $acrName ] || [ -z $spName ]; then
  echo "Usage: $0 -g <resourceGroup> -r <acrName> -p <spName> [-l <location>]" >&2
  exit 1
fi

# Set default location 
location=${location:-"australiasoutheast"}

# Set subscriptionId from current context
subscriptionId=$(az account show --query id -o tsv)

# Create resource group
az group create --name $resourceGroupName --location $location 

# Create container registry
az acr create --resource-group $resourceGroupName --name $acrName --sku Basic

# Create service principal 
spCredential=$(az ad sp create-for-rbac --name $spName --role Contributor --scopes /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName --json-auth)
echo $spCredential

