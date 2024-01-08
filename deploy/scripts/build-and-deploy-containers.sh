#!/bin/zsh

# Required
resourceGroupName=""
acrName=""
spName=""

# Parse arguments
while getopts ":g:r:l:p:" option; do
  case $option in
    g) resourceGroupName=${OPTARG};;
    r) acrName=${OPTARG};;
  esac
done

# Validate required parameters
if [ -z $resourceGroupName ] || [ -z $acrName ]; then
  echo "Usage: $0 -g <resourceGroup> -r <acrName> -p <spName>" >&2
  exit 1
fi

az acr build --registry $acrName --image microservices/vehicle:latest --file ../../src/Microservices/Vehicles/dockerfile ../../src/Microservices/Vehicles
az acr build --registry $acrName --image microservices/trafficevents:latest --file ../../src/Microservices/TrafficEvents//dockerfile ../../src/Microservices/trafficevents
az acr build --registry $acrName --image microservices/finemanager:latest --file ../../src/Microservices/FineManager/dockerfile ../../src/Microservices/FineManager

