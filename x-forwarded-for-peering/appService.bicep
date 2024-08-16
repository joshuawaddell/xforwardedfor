// Parameters
//////////////////////////////////////////////////
@description('The password of the admin user.')
@secure()
param adminPassword string

@description('The name of the admin user.')
param adminUserName string

@description('The resource ID of the App Service Private Dns Zone.')
param appServicePrivateDnsZoneId string

@description('The name of the App Service Private Endpoint.')
param appServicePrivateEndpointName string

@description('The name of the App Service Private Endpoint Nic.')
param appServicePrivateEndpointNicName string

@description('The private IP address of the App Service Private Endpoint.')
param appServicePrivateEndpointPrivateIpAddress string

@description('The resource ID of the App Service Private Endpoint Subnet.')
param appServicePrivateEndpointSubnetId string

@description('The name of the App Service Server.')
param appServiceName string

@description('The name of the Azure SQL Database.')
param azureSqlDatabaseName string

@description('The FQDN of the Azure SQL Server')
param azureSqlServerFqdn string

@description('The docker image location.')
param dockerImage string

@description('The location for all resources.')
param location string

@description('The resource ID of the App Service Plan.')
param serverFarmId string

@description('The resource ID of the Virtual Network Integration Subnet.')
param vnetIntegrationSubnetId string

// Resource - App Service
//////////////////////////////////////////////////
resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceName
  location: location
  kind: 'container'
  properties: {
    httpsOnly: true
    serverFarmId: serverFarmId
    virtualNetworkSubnetId: vnetIntegrationSubnetId
    vnetRouteAllEnabled: true
    siteConfig: {
      linuxFxVersion: dockerImage
      appSettings: [
        {
          name: 'DefaultSqlConnectionSqlConnectionString'
          value: 'Data Source=tcp:${azureSqlServerFqdn},1433;Initial Catalog=${azureSqlDatabaseName};User Id=${adminUserName}@${azureSqlServerFqdn};Password=${adminPassword};'
        }
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
      ]
    }
  }
}

// Resource - Private Endpoint
//////////////////////////////////////////////////
resource appServicePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: appServicePrivateEndpointName
  location: location
  properties: {
    customNetworkInterfaceName: appServicePrivateEndpointNicName
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          groupId: 'sites'
          memberName: 'sites'
          privateIPAddress: appServicePrivateEndpointPrivateIpAddress
        }
      }
    ]
    subnet: {
      id: appServicePrivateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: appServicePrivateEndpointName
        properties: {
          privateLinkServiceId: appService.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

// Resource - Private Endpoint Dns Group - Private Endpoint
//////////////////////////////////////////////////
resource appServicePrivateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: appServicePrivateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: appServicePrivateDnsZoneId
        }
      }
    ]
  }
}

// Outputs
//////////////////////////////////////////////////
output appServiceCustomDomainVerificationId string = appService.properties.customDomainVerificationId
output appServiceDefaultHostName string = appService.properties.defaultHostName
output appServiceName string = appService.name
