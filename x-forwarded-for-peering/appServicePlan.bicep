// Parameters
//////////////////////////////////////////////////
@description('The kind of the App Service Plan.')
param appServicePlanKind string

@description('The name of the App Service Plan.')
param appServicePlanName string

@description('The SKU name of the App Service Plan.')
param appServicePlanSkuName string

@description('The SKU capacity of the App Service Plan.')
param appServicePlanSkuCapacity int

@description('The location for all resources.')
param location string

// Resource - App Service Plan
//////////////////////////////////////////////////
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  kind: appServicePlanKind
  sku: {
    name: appServicePlanSkuName
    capacity: appServicePlanSkuCapacity
  }
  properties: {
    reserved: true
  }
}

// Outputs
//////////////////////////////////////////////////
output serverFarmId string = appServicePlan.id
