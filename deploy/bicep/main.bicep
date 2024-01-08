@description('Location for all resources.')
param location string = resourceGroup().location

@description('Base container or login url for registry containing  images (). E.g. registry.azurecr.io.')
param containerRegistry string

@description('The service principal client id used to deploy the app and access the container registry.')
param servicePrincipalClientId string

@description('The service principal secret or password.')
@secure()
param servicePrincipalPassword string

@description('The Id or Object Id of the service principal corresponding to the provided client id. Note access to key vault requires this rather than the client id.')
param servicePrincipalId string

@description('The name of the key vault to deploy.')
param keyVaultName string = 'keyvault'

@description('Name of the container group to deploy')
param containerGroupName string = 'trafficfineappcontainergroup'

@description('Frontend/public port to open on the container.')
param frontendBasePort int = 80

@description('Backend/private port the container is listening on')
param backendBasePort int = 8080

@description('The number of CPU cores to allocate to the container.')
param cpuCores int = 1

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb int = 2

@description('The name of the virtual network that the container group will be deployed to.')
param virtualNetworkName string = 'vnet'

@description('The subnet the container group is assigned to.')
param containerSubnet string = 'container-subnet'

@description('The subnet which the app gateway is assigned to.')
param gatewaySubnet string = 'gateway-subnet'

@description('The name of the app gateway.')
param gatewayName string = 'appgateway'

@description('The behavior of Azure runtime if container has stopped.')
@allowed([
  'Always'
  'Never'
  'OnFailure'
])
param restartPolicy string = 'Always'




module network 'modules/vnet.bicep' = {
  name: virtualNetworkName
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    subnet1Name: gatewaySubnet
    subnet2Name: containerSubnet
  }
}

module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsights'
  params: {
    location: location
  }
}

module keyVault 'modules/keyVault.bicep' = {
  name: keyVaultName
  params: {
    location: location
    keyVaultName: keyVaultName
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    servicePrincipalId: servicePrincipalId
  }
}

module containers 'modules/containers.bicep' = {
  name: containerGroupName
  params: {
    location: location
    pullFromRegistry: containerRegistry
    registryUser: servicePrincipalClientId
    registryPass: servicePrincipalPassword
    groupName: containerGroupName
    backendBasePort: backendBasePort
    virtualNetworkName: virtualNetworkName
    subnetName: containerSubnet
    subnetId: network.outputs.subnet2ResourceId
    restartPolicy: restartPolicy
    cpuCores: cpuCores
    memoryInGb: memoryInGb
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
  }
  dependsOn: [
    network, appInsights
  ]
}


module gateway 'modules/gateway.bicep' = {
  name: gatewayName
  params: {
    location: location
    applicationGatewayName: gatewayName
    virtualNetworkName: virtualNetworkName
    subnetName: gatewaySubnet
    containerGroupName: containerGroupName
    frontendBasePort: frontendBasePort
    backendBasePort: backendBasePort
  }
  dependsOn: [
    containers
  ]
}

