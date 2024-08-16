// Parameters
//////////////////////////////////////////////////
@description('The custom FQDN of the App Service.')
param appServiceFqdn string

@description('The name of the App Service Server.')
param appServiceName string

@description('The name of the certificate.')
param certificateName string

@description('The Id of the Key Vault.')
param keyVaultId string

@description('The name of the Key Vault secret.')
param keyVaultSecretName string

@description('The location for all resources.')
param location string

@description('The Id of the App Service Plan.')
param serverFarmId string

// Resource - App Service - Custom Domain
//////////////////////////////////////////////////
resource customDomain 'Microsoft.Web/sites/hostNameBindings@2023-12-01' = {
  name: '${appServiceName}/${appServiceFqdn}'
  properties: {
    hostNameType: 'Verified'
    sslState: 'Disabled'
    customHostNameDnsRecordType: 'CName'
    siteName: appServiceName
  }
}

// Resource - App Service - Certificate
//////////////////////////////////////////////////
resource certificate 'Microsoft.Web/certificates@2023-12-01' = {
  name: certificateName
  location: location
  properties: {
    keyVaultId: keyVaultId
    keyVaultSecretName: keyVaultSecretName
    serverFarmId: serverFarmId
  }
}

// Outputs
//////////////////////////////////////////////////
output certificateThumbprint string =  certificate.properties.thumbprint
