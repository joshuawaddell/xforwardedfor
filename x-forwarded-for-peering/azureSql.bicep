// Parameters
//////////////////////////////////////////////////
@description('The password of the admin user.')
@secure()
param adminPassword string

@description('The name of the admin user.')
param adminUserName string

@description('The resource ID of the Azure SQL Private Dns Zone.')
param azureSqlPrivateDnsZoneId string

@description('The name of the Azure SQL Private Endpoint.')
param azureSqlPrivateEndpointName string

@description('The name of the Azure SQL Private Endpoint Nic.')
param azureSqlPrivateEndpointNicName string

@description('The private IP address of the Azure SQL Private Endpoint.')
param azureSqlPrivateEndpointPrivateIpAddress string

@description('The resource ID of the Azure SQL Private Endpoint Subnet.')
param azureSqlPrivateEndpointSubnetId string

@description('The name of the Azure SQL Server.')
param azureSqlServerName string

@description('The name of the Azure SQL Database.')
param azureSqlDatabaseName string

@description('The location for all resources.')
param location string

// Resource - Sql Server
//////////////////////////////////////////////////
resource azureSqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: azureSqlServerName
  location: location
  properties: {
    publicNetworkAccess: 'Disabled'
    administratorLogin: adminUserName
    administratorLoginPassword: adminPassword
    version: '12.0'
  }
}

// Resource - Sql Database
//////////////////////////////////////////////////
resource azureSqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: azureSqlServer
  name: azureSqlDatabaseName
  location: location
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 40
  }
}

// Resource - Private Endpoint
//////////////////////////////////////////////////
resource azureSqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: azureSqlPrivateEndpointName
  location: location
  properties: {
    customNetworkInterfaceName: azureSqlPrivateEndpointNicName
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          groupId: 'sqlServer'
          memberName: 'sqlServer'
          privateIPAddress: azureSqlPrivateEndpointPrivateIpAddress
        }
      }
    ]
    subnet: {
      id: azureSqlPrivateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: azureSqlPrivateEndpointName
        properties: {
          privateLinkServiceId: azureSqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

// Resource - Private Endpoint Dns Group - Private Endpoint
//////////////////////////////////////////////////
resource azureSqlPrivateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: azureSqlPrivateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: azureSqlPrivateDnsZoneId
        }
      }
    ]
  }
}

// Outputs
//////////////////////////////////////////////////
output azureSqlServerAdministratorLogin string = azureSqlServer.properties.administratorLogin
output azureSqlServerFqdn string = azureSqlServer.properties.fullyQualifiedDomainName
