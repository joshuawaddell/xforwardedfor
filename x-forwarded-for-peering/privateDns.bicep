// Parameters
//////////////////////////////////////////////////
@description('The name of the App Service DNS Zone.')
param appServicePrivateDnsZoneName string

@description('The name of the Azure Sql Private DNS Zone.')
param azureSqlPrivateDnsZoneName string

@description('The resource ID of the hub Virtual Network.')
param hubVirtualNetworkId string

@description('The name of the hub Virtual Network.')
param hubVirtualNetworkName string

@description('The resource ID of the spoke Virtual Network.')
param spokeVirtualNetworkId string

@description('The name of the spoke Virtual Network.')
param spokeVirtualNetworkName string

// Resource - Private Dns Zone - Privatelink.Azurewebsites.Net
//////////////////////////////////////////////////
resource appServicePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: appServicePrivateDnsZoneName
  location: 'global'
}

// Resource Virtual Network Link - Privatelink.Azurewebsites.Net to Hub Virtual Network
//////////////////////////////////////////////////
resource hubVirtualNetworkLinkAppService 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: appServicePrivateDnsZone
  name: '${hubVirtualNetworkName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVirtualNetworkId
    }
  }
}

// Resource Virtual Network Link - Privatelink.Azurewebsites.Net to Spoke Virtual Network
//////////////////////////////////////////////////
resource spokeVirtualNetworkLinkAppService 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: appServicePrivateDnsZone
  name: '${spokeVirtualNetworkName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVirtualNetworkId
    }
  }
}

// Resource - Private Dns Zone - Privatelink.Database.Windows.Net
//////////////////////////////////////////////////
resource azureSqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: azureSqlPrivateDnsZoneName
  location: 'global'
}

// Resource Virtual Network Link - Privatelink.Database.Windows.Net to Hub Virtual Network
//////////////////////////////////////////////////
resource hubVirtualNetworkLinkAzureSql 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: azureSqlPrivateDnsZone
  name: '${hubVirtualNetworkName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVirtualNetworkId
    }
  }
}

// Resource Virtual Network Link - Privatelink.Database.Windows.Net to Hub Virtual Network
//////////////////////////////////////////////////
resource spokeVirtualNetworkLinkAzureSql 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: azureSqlPrivateDnsZone
  name: '${spokeVirtualNetworkName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVirtualNetworkId
    }
  }
}

// Outputs
//////////////////////////////////////////////////
output appServicePrivateDnsZoneId string = appServicePrivateDnsZone.id
output azureSqlPrivateDnsZoneId string = azureSqlPrivateDnsZone.id
