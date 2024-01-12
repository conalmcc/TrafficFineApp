@description('Location for all resources.')
param location string = resourceGroup().location

param managedIdentityName string

@description('Base container registry url for microservice container images')
param pullFromRegistry string

@description('Name for the container group')
param groupName string

@description('Port to open on the container and the public IP address.')
param backendBasePort int

@description('The number of CPU cores to allocate to the container.')
param cpuCores int

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb int

param keyVaultName string



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


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdentityName
}



resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: groupName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${managedIdentity.id}': {} }
  }
  properties: {
    
    imageRegistryCredentials: [
      {
        server: pullFromRegistry 
        identity: managedIdentity.id
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
              name: 'KeyVaultName'
              value: keyVaultName
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
      type: 'Public'
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

  ]
}

output containerIPv4Address string = containerGroup.properties.ipAddress.ip
