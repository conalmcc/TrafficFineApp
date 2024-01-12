@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the managed identity to create.')
param managedIdentityName string = 'traffic-app-identity2'

@description('Base container or login url for registry containing  images (). E.g. registry.azurecr.io.')
param containerRegistry string

@description('The name of the key vault to deploy.')
param keyVaultName string

@description('Name of the container group to deploy')
param containerGroupName string = 'trafficfineappcontainergroup'

@description('Starting port the containers are listening on')
param backendBasePort int = 8080

@description('The number of CPU cores to allocate to the container.')
param cpuCores int = 1

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb int = 2


@description('The behavior of Azure runtime if container has stopped.')
@allowed([
  'Always'
  'Never'
  'OnFailure'
])
param restartPolicy string = 'Always'


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(managedIdentity.id, resourceGroup().id, 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: managedIdentity.properties.principalId
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
    appInsightsConnectionString: appInsights.outputs.connectionString
    servicePrincipalId: managedIdentity.properties.principalId
  }
  dependsOn: [
    appInsights, roleAssignment
  ]
}


module containers 'modules/containers.bicep' = {
  name: containerGroupName
  params: {
    location: location
    pullFromRegistry: containerRegistry
    groupName: containerGroupName
    backendBasePort: backendBasePort
    restartPolicy: restartPolicy
    cpuCores: cpuCores
    memoryInGb: memoryInGb
    keyVaultName: keyVaultName
    managedIdentityName: managedIdentityName
  }
  dependsOn: [
    appInsights, keyVault, managedIdentity, roleAssignment
  ]
}


