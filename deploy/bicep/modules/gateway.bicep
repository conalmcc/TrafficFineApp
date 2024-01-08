param location string

param virtualNetworkName string 
param subnetName string

param applicationGatewayName string
param containerGroupName string

param frontendBasePort int = 80
param backendBasePort int = 8080


resource network 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: virtualNetworkName
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' existing = {
  name: containerGroupName
}


resource gatewayPublicIPAddress 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'gatewayPublicIpAddress'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}


resource fineManagerApplicationGateway 'Microsoft.Network/applicationGateways@2023-06-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    sku: {
      name: 'Standard_Small'
      tier: 'Standard'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', 'gatewayPublicIpAddress')
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_1'
        properties: {
          port: frontendBasePort
        }
      }
      {
        name: 'port_2'
        properties: {
          port: frontendBasePort+1
        }
      }
      {
        name: 'port_3'
        properties: {
          port: frontendBasePort+2
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'ContainerGroupBackend'
        properties: {
          backendAddresses: [
            {
              ipAddress: containerGroup.properties.ipAddress.ip
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'BackendSettings1'
        properties: {
          port: backendBasePort
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'check-containers-up')
          }
        }
      }
      {
        name: 'BackendSettings2'
        properties: {
          port: backendBasePort+1
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'check-containers-up')
          }
        }
      }
      {
        name: 'BackendSettings3'
        properties: {
          port: backendBasePort+2
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'check-containers-up')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpListener1'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontEndIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port_1')
          }
          protocol: 'Http'
          hostNames: []
          requireServerNameIndication: false
          customErrorConfigurations: []
        }
      }
      {
        name: 'httpListener2'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontEndIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port_2')
          }
          protocol: 'Http'
          hostNames: []
          requireServerNameIndication: false
          customErrorConfigurations: []
        }
      }
      {
        name: 'httpListener3'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontEndIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port_3')
          }
          protocol: 'Http'
          hostNames: []
          requireServerNameIndication: false
          customErrorConfigurations: []
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'HttpToContainerGroupRoutingRule1'
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'httpListener1')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'ContainerGroupBackend')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'BackendSettings1')
          }
        }
      }
      {
        name: 'HttpToContainerGroupRoutingRule2'
        properties: {
          ruleType: 'Basic'
          priority: 2
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'httpListener2')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'ContainerGroupBackend')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'BackendSettings2')
          }
        }
      }
      {
        name: 'HttpToContainerGroupRoutingRule3'
        properties: {
          ruleType: 'Basic'
          priority: 3
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'httpListener3')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'ContainerGroupBackend')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'BackendSettings3')
          }
        }
      }
    ]
    probes: [
      {
        name: 'check-containers-up'
        properties: {
          protocol: 'Http'
          host: containerGroup.properties.ipAddress.ip
          port: backendBasePort
          path: '/swagger'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {}
        }
      }
    ]
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 10
    }
  }
  dependsOn: [
    network, containerGroup
]
}
