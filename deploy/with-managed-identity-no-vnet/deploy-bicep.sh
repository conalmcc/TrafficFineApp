#!/bin/zsh

# Required
resourceGroupName=""
acrName=""
kvName=""

# Optional
location=""

# Parse arguments
while getopts ":g:r:l:c:p:k:" option; do
  case $option in
    g) resourceGroupName=${OPTARG};;
    r) acrName=${OPTARG};;
    l) location=${OPTARG};;
    k) kvName=${OPTARG};;
  esac
done

# Validate required parameters
if [ -z $resourceGroupName ] || [ -z $acrName ] || [ -k $kvName ]; then
  echo "Usage: $0 -g <resourceGroup> -r <acrName> -k [<keyVaultName>] [-l <location>]" >&2
  exit 1
fi

# Set default location 
location=${location:-"australiasoutheast"}

# Deploy the Bicep template
az deployment group create --resource-group $resourceGroupName --template-file ./main.bicep --parameters location=$location containerRegistry=$acrName".azurecr.io" keyVaultName=$kvName
