@description('Location for all resources.')
param location string = resourceGroup().location

@description('Base container registry url for microservice container images')
param pullFromRegistry string

param registryUser string
param registryPass string

@description('Name for the container group')
param groupName string

@description('Port to open on the container and the public IP address.')
param backendBasePort int

@description('The number of CPU cores to allocate to the container.')
param cpuCores int

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb int

param virtualNetworkName string
param subnetName string
param subnetId string

@secure()
param appInsightsInstrumentationKey string


@description('The behavior of Azure runtime if container has stopped.')
@allowed([
  'Always'
  'Never'
  'OnFailure'
])
param restartPolicy string = 'Never'


var vehicleContainerName = 'vehicle'
var vehicleContainerImage = toLower('${pullFromRegistry}/microservices/${vehicleContainerName}:latest')

var trafficEventsContainerName = 'trafficevents'
var trafficEventsContainerImage = toLower('${pullFromRegistry}/microservices/${trafficEventsContainerName}:latest')

var fineManagerContainerName = 'finemanager'
var fineManagerContainerImage = toLower('${pullFromRegistry}/microservices/${fineManagerContainerName}:latest')



resource network 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: virtualNetworkName
}



resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: groupName
  location: location
  properties: {
    imageRegistryCredentials: [
      {
        server: pullFromRegistry
        username: registryUser
        password: registryPass
      }
    ]
    subnetIds: [
      {
        id: subnetId
        name: subnetName
      }
    ]
    containers: [
      {
        name: vehicleContainerName
        properties: {
          image: vehicleContainerImage
          environmentVariables: [
            {
              name: 'ASPNETCORE_HTTP_PORTS'
              value: '${backendBasePort}'
            }
            {
              name: 'AppInsights_InstrumentationKey'
              value: appInsightsInstrumentationKey


            }
          ]
          ports: [
            {
              port: backendBasePort
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
        }
      }
      {
        name: trafficEventsContainerName
        properties: {
          image: trafficEventsContainerImage
          environmentVariables: [
            {
              name: 'ASPNETCORE_HTTP_PORTS'
              value: '${backendBasePort + 1}'
            }
            {
              name: 'AppInsights_InstrumentationKey'
              value: appInsightsInstrumentationKey
            }
          ]
          ports: [
            {
              port: backendBasePort + 1
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
        }
      }
      {
        name: fineManagerContainerName
        properties: {
          image: fineManagerContainerImage
          environmentVariables: [
            {
              name: 'ASPNETCORE_HTTP_PORTS'
              value: '${backendBasePort + 2}'
            }
            {
              name: 'AppInsights_InstrumentationKey'
              value: appInsightsInstrumentationKey
            }
          ]
          ports: [
            {
              port: backendBasePort + 2
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: restartPolicy
    ipAddress: {
      type: 'Private'
      ports: [
        {
          port: backendBasePort
          protocol: 'TCP'
        }
        {
          port: backendBasePort + 1
          protocol: 'TCP'
        }
        {
          port: backendBasePort + 2
          protocol: 'TCP'
        }
      ]
    }
  }
  dependsOn: [
    network
  ]
}

output containerIPv4Address string = containerGroup.properties.ipAddress.ip
