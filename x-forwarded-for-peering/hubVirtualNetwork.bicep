// Parameters
//////////////////////////////////////////////////
@description('The name of the Application Gateway Subnet.')
param applicationGatewaySubnetName string

@description('The address prefix of the Application Gateway Subnet.')
param applicationGatewaySubnetPrefix string

@description('The location for all resources.')
param location string

@description('The name of the Virtual Network.')
param virtualNetworkName string

@description('The address prefix of the Virtual Network.')
param virtualNetworkPrefix string

// Resource - Virtual Network
//////////////////////////////////////////////////
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkPrefix
      ]
    }
    subnets: [
      {
        name: applicationGatewaySubnetName
        properties: {
          addressPrefix: applicationGatewaySubnetPrefix
        }
      }
    ]
  }
  resource applicationGatewaySubnet 'subnets' existing = {
    name: applicationGatewaySubnetName
  }
}

// Outputs
//////////////////////////////////////////////////
output applicationGatewaySubnetId string = virtualNetwork::applicationGatewaySubnet.id

output virtualNetworkId string = virtualNetwork.id
