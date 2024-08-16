// Parameters
//////////////////////////////////////////////////
@description('The password of the admin user.')
@secure()
param adminPassword string

@description('The name of the admin user.')
param adminUserName string

@description('The name of the DNS domain.')
param domainName string

@description('The location for all resources.')
param location string = resourceGroup().location

@description('The name of the workload.')
param workload string

// Variables - Existing Resources
//////////////////////////////////////////////////
var keyVaultName = 'vault-${workload}'
var keyVaultSecretName = 'wildcard'
var managedIdentityName = 'uami-${workload}'

// Existing Resource - Dns Zone
//////////////////////////////////////////////////
resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: domainName
}

// Existing Resource - Key Vault
//////////////////////////////////////////////////
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
  resource keyVaultSecret 'secrets' existing = {
    name: keyVaultSecretName
  }
}

// Existing Resource - Managed Identity
//////////////////////////////////////////////////
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

// Variables - Hub Virtual Network
//////////////////////////////////////////////////
var applicationGatewaySubnetName = 'snet-${workload}-applicationgateway'
var applicationGatewaySubnetPrefix = '10.0.0.0/24'
var hubVirtualNetworkName = 'vnet-${workload}-hub'
var hubVirtualNetworkPrefix = '10.0.0.0/16'

// Module - Hub Virtual Network
//////////////////////////////////////////////////
module hubVirtualNetworkModule 'hubVirtualNetwork.bicep' = {
  name: 'hubVirtualNetworkDeployment'
  params: {
    location: location
    applicationGatewaySubnetName: applicationGatewaySubnetName
    applicationGatewaySubnetPrefix: applicationGatewaySubnetPrefix
    virtualNetworkName: hubVirtualNetworkName
    virtualNetworkPrefix: hubVirtualNetworkPrefix
  }
}

// Variables - Spoke Virtual Network
//////////////////////////////////////////////////
var appServiceSubnetName = 'snet-${workload}-appService'
var appServiceSubnetPrefix = '10.1.1.0/24'
var azureSqlDatabaseSubnetName = 'snet-${workload}-azureSqlDatabase'
var azureSqlDatabaseSubnetPrefix = '10.1.3.0/24'
var spokeVirtualNetworkName = 'vnet-${workload}-spoke'
var spokeVirtualNetworkPrefix = '10.1.0.0/16'
var vnetIntegrationSubnetName = 'snet-${workload}-vnetIntegration'
var vnetIntegrationSubnetPrefix = '10.1.2.0/24'

// Module - Spoke Virtual Network
//////////////////////////////////////////////////
module spokeVirtualNetworkModule 'spokeVirtualNetwork.bicep' = {
  name: 'spokeVirtualNetworkDeployment'
  params: {
    location: location
    appServiceSubnetName: appServiceSubnetName
    appServiceSubnetPrefix: appServiceSubnetPrefix
    azureSqlDatabaseSubnetName: azureSqlDatabaseSubnetName
    azureSqlDatabaseSubnetPrefix: azureSqlDatabaseSubnetPrefix
    virtualNetworkName: spokeVirtualNetworkName
    virtualNetworkPrefix: spokeVirtualNetworkPrefix
    vnetIntegrationSubnetName: vnetIntegrationSubnetName
    vnetIntegrationSubnetPrefix: vnetIntegrationSubnetPrefix
  }
}

// Module - Virtual Network Peering
//////////////////////////////////////////////////
module virtualNetworkPeeringModule 'virtualNetworkPeering.bicep' = {
  name: 'virtualNetworkPeeringModule'
  params: {
    hubVirtualNetworkId: hubVirtualNetworkModule.outputs.virtualNetworkId
    hubVirtualNetworkName: hubVirtualNetworkName
    spokeVirtualNetworkId: spokeVirtualNetworkModule.outputs.virtualNetworkId
    spokeVirtualNetworkName: spokeVirtualNetworkName
  }
}

// Variables - Private DNS
//////////////////////////////////////////////////
var appServicePrivateDnsZoneName = 'privatelink.azurewebsites.net'
var azureSqlPrivateDnsZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'

// Module - Private DNS
//////////////////////////////////////////////////
module privateDnsModule 'privateDns.bicep' = {
  name: 'privateDnsDeployment'
  params: {
    appServicePrivateDnsZoneName: appServicePrivateDnsZoneName
    azureSqlPrivateDnsZoneName: azureSqlPrivateDnsZoneName
    hubVirtualNetworkId: hubVirtualNetworkModule.outputs.virtualNetworkId
    hubVirtualNetworkName: hubVirtualNetworkName
    spokeVirtualNetworkId: spokeVirtualNetworkModule.outputs.virtualNetworkId
    spokeVirtualNetworkName: spokeVirtualNetworkName
  }
}

// Variables - Azure SQL
//////////////////////////////////////////////////
var azureSqlDatabaseName = 'sqldb-${workload}'
var azureSqlPrivateEndpointName = 'pe-${workload}-azureSql'
var azureSqlPrivateEndpointNicName = 'nic-${workload}-azureSql'
var azureSqlPrivateEndpointPrivateIpAddress = '10.1.3.4'
var azureSqlServerName = 'sql-${workload}'

// Module - Azure SQL
//////////////////////////////////////////////////
module azureSqlModule 'azureSql.bicep' = {
  name: 'azureSqlDeployment'
  params: {
    location: location
    adminPassword: adminPassword
    adminUserName: adminUserName
    azureSqlDatabaseName: azureSqlDatabaseName
    azureSqlPrivateDnsZoneId: privateDnsModule.outputs.azureSqlPrivateDnsZoneId
    azureSqlPrivateEndpointName: azureSqlPrivateEndpointName
    azureSqlPrivateEndpointNicName: azureSqlPrivateEndpointNicName
    azureSqlPrivateEndpointPrivateIpAddress: azureSqlPrivateEndpointPrivateIpAddress
    azureSqlPrivateEndpointSubnetId: spokeVirtualNetworkModule.outputs.azureSqlDatabaseSubnetId
    azureSqlServerName: azureSqlServerName
  }
}

// Variables - App Service Plan
//////////////////////////////////////////////////
var appServicePlanKind = 'Linux'
var appServicePlanName = 'plan-${workload}'
var appServicePlanSkuCapacity = 1
var appServicePlanSkuName = 'P1v3'

// Module - App Service Plan
//////////////////////////////////////////////////
module appServicePlanModule 'appServicePlan.bicep' = {
  name: 'appServicePlanDeployment'
  params: {
    location: location
    appServicePlanKind: appServicePlanKind
    appServicePlanName: appServicePlanName
    appServicePlanSkuCapacity: appServicePlanSkuCapacity
    appServicePlanSkuName: appServicePlanSkuName
  }
}

// Variables - App Service
//////////////////////////////////////////////////
var appServiceName = 'app-${workload}'
var appServicePrivateEndpointName = 'pe-${workload}-appService'
var appServicePrivateEndpointNicName = 'nic-${workload}-appService'
var appServicePrivateEndpointPrivateIpAddress = '10.1.1.4'
var dockerImage = 'DOCKER|jelledruyts/inspectorgadget:latest'

// Module - App Service
//////////////////////////////////////////////////
module appServiceModule 'appService.bicep' = {
  name: 'appServiceDeployment'
  params: {
    location: location
    adminPassword: adminPassword
    adminUserName: adminUserName
    appServiceName: appServiceName
    appServicePrivateDnsZoneId: privateDnsModule.outputs.appServicePrivateDnsZoneId
    appServicePrivateEndpointName: appServicePrivateEndpointName
    appServicePrivateEndpointNicName: appServicePrivateEndpointNicName
    appServicePrivateEndpointPrivateIpAddress: appServicePrivateEndpointPrivateIpAddress
    appServicePrivateEndpointSubnetId: spokeVirtualNetworkModule.outputs.appServiceSubnetId
    azureSqlDatabaseName: azureSqlDatabaseName
    azureSqlServerFqdn: azureSqlModule.outputs.azureSqlServerFqdn
    dockerImage: dockerImage
    serverFarmId: appServicePlanModule.outputs.serverFarmId
    vnetIntegrationSubnetId: spokeVirtualNetworkModule.outputs.vnetIntegrationSubnetId
  }
}

// Variables - App Service - Dns Records
//////////////////////////////////////////////////
var appServiceCnameRecords = [
  {
    name: workload
    ttl: 3600
    cname: appServiceModule.outputs.appServiceDefaultHostName
  }
]
var appServiceTxtRecords = [
  {
    name: 'asuid.${workload}'
    ttl: 3600
    value: appServiceModule.outputs.appServiceCustomDomainVerificationId
  }
]

// Module - App Service - Dns Zone Records
//////////////////////////////////////////////////
module appServiceDnsRecordsModule 'appServiceDnsZoneRecords.bicep' = {
  name: 'appServiceDnsZoneRecordsDeployment'
  params: {
    appServiceCnameRecords: appServiceCnameRecords
    appServiceTxtRecords: appServiceTxtRecords
    dnsZoneName: dnsZone.name
  }
}

// Variables - App Service - TLS Settings
//////////////////////////////////////////////////
var certificateName = 'wildcard'

// Module - App Service - TLS Settings
//////////////////////////////////////////////////
module appServiceTlsSettingsModule 'appServiceTls.bicep' = {
  name: 'appServiceTlsSettingsDeployment'
  dependsOn: [
    appServiceDnsRecordsModule
  ]
  params: {    
    appServiceFqdn: '${workload}.${domainName}'
    appServiceName: appServiceName
    certificateName: certificateName
    keyVaultId: keyVault.id
    keyVaultSecretName: keyVaultSecretName
    location: location
    serverFarmId: appServicePlanModule.outputs.serverFarmId
  }
}

// Module - App Service Sni Enable
//////////////////////////////////////////////////
module appServiceSniEnableModule 'appServiceSniEnable.bicep' = {
  name: 'appServiceSniEnableDeployment'
  params: {
    appServiceFqdn: '${workload}.${domainName}'
    appServiceName: appServiceName
    certificateThumbprint: appServiceTlsSettingsModule.outputs.certificateThumbprint
  }
}

// Variables - Application Gateway
//////////////////////////////////////////////////
var applicationGatewayName = 'appgw-${workload}'
var certificateDataPassword = ''
var publicIpAddressName = 'pip-${workload}-appgw'

// Module - ApplicationGateway
//////////////////////////////////////////////////
module applicationGatewayModule 'applicationGateway.bicep' = {
  name: 'applicationGatewayDeployment'
  params: {
    location: location
    appServiceDefaultHostName: appServiceModule.outputs.appServiceDefaultHostName
    appServiceFqdn: '${workload}.${domainName}'
    applicationGatewayName: applicationGatewayName
    applicationGatewaySubnetId: hubVirtualNetworkModule.outputs.applicationGatewaySubnetId
    certificateData: keyVault.getSecret('wildcard')
    certificateDataPassword: certificateDataPassword
    certificateName: certificateName
    publicIpAddressName: publicIpAddressName
    userAssignedManagedIdentityId: managedIdentity.id
  }
}
