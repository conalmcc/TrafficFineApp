@description('Location for all resources.')
param location string = resourceGroup().location

@description('Base container registry url for microservice container images.')
param containerRegistry string = 'finemanagerapp.azurecr.io'

@description('Container registry username.')
param registryUser string

@description('Container registry password.')
param registryPass string

@description('Name for the container group')
param containerGroupName string = 'trafficfineappcontainergroup'

@description('Port to open on the container and the public IP address.')
param frontendBasePort int = 80

@description('Port to open on the container and the public IP address.')
param backendBasePort int = 8080

@description('The number of CPU cores to allocate to the container.')
param cpuCores int = 1

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb int = 2

@description('The name of the virtual network that the container group will be deployed to.')
param virtualNetworkName string = 'fineapp-vnet'

@description('The subnet the container group is assigned to.')
param containerSubnet string = 'fineapp-subnet'

@description('The subnet which the app gateway is assigned to.')
param gatewaySubnet string = 'fineapp-gateway-subnet'

@description('The name of the app gateway.')
param gatewayName string = 'finemanagerappgateway'

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


module containers 'modules/containers.bicep' = {
  name: containerGroupName
  params: {
    location: location
    pullFromRegistry: containerRegistry
    registryUser: registryUser
    registryPass: registryPass
    groupName: containerGroupName
    backendBasePort: backendBasePort
    virtualNetworkName: virtualNetworkName
    subnetName: containerSubnet
    subnetId: network.outputs.subnet2ResourceId
    restartPolicy: restartPolicy
    cpuCores: cpuCores
    memoryInGb: memoryInGb
  }
  dependsOn: [
    network
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


