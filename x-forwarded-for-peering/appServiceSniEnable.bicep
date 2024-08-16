// Parameters
//////////////////////////////////////////////////
@description('The custom FQDN of the App Service.')
param appServiceFqdn string

@description('The name of the App Service Server.')
param appServiceName string

@description('The value of the Certificate Thumbprint')
param certificateThumbprint string

// Resource - App Service - Sni Enable
//////////////////////////////////////////////////
resource appServiceSniEnable 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  name: '${appServiceName}/${appServiceFqdn}'
  properties: {
    sslState: 'SniEnabled'
    thumbprint: certificateThumbprint
  }
}
