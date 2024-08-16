// Parameters
//////////////////////////////////////////////////
@description('The name of the App Service Subnet.')
param appServiceSubnetName string

@description('The address prefix of the App Service Subnet.')
param appServiceSubnetPrefix string

@description('The name of the Azure SQL Database Subnet.')
param azureSqlDatabaseSubnetName string

@description('The address prefix of the Azure SQL Database Subnet.')
param azureSqlDatabaseSubnetPrefix string

@description('The location for all resources.')
param location string

@description('The name of the Virtual Network.')
param virtualNetworkName string

@description('The address prefix of the Virtual Network.')
param virtualNetworkPrefix string

@description('The name of the Virtual Network Integration Subnet.')
param vnetIntegrationSubnetName string

@description('The address prefix of the Virtual Network Integration Subnet.')
param vnetIntegrationSubnetPrefix string

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
        name: appServiceSubnetName
        properties: {
          addressPrefix: appServiceSubnetPrefix
        }
      }
      {
        name: vnetIntegrationSubnetName
        properties: {
          addressPrefix: vnetIntegrationSubnetPrefix
          delegations: [
            {
              name: 'appServicePlanDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: azureSqlDatabaseSubnetName
        properties: {
          addressPrefix: azureSqlDatabaseSubnetPrefix
        }
      }
    ]
  }
  resource appServiceSubnet 'subnets' existing = {
    name: appServiceSubnetName
  }
  resource vnetIntegrationSubnet 'subnets' existing = {
    name: vnetIntegrationSubnetName
  }
  resource azureSqlDatabaseSubnet 'subnets' existing = {
    name: azureSqlDatabaseSubnetName
  }
}

// Outputs
//////////////////////////////////////////////////
output appServiceSubnetId string = virtualNetwork::appServiceSubnet.id
output azureSqlDatabaseSubnetId string = virtualNetwork::azureSqlDatabaseSubnet.id
output virtualNetworkId string = virtualNetwork.id
output vnetIntegrationSubnetId string = virtualNetwork::vnetIntegrationSubnet.id
