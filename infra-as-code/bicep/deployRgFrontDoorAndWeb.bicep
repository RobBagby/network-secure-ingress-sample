targetScope = 'subscription'

@description('This is the prefix for each Azure resource name')
param assetPrefix string = 'bagbyfrtda'

@description('The location of the resource group, vnet, jumpbox and bastion.')
param location string = 'centralus'

@description('The name of the SKU to use when creating the Azure Storage account.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param storageSkuName string = 'Standard_LRS'

param storageAccountWebsiteContainerName string = 'web'

param storageAccountWebsiteLocations array = [
  'eastus'
  'westus3'
]

@description('The name of the SKU to use when creating the Front Door profile. If you use Private Link this must be set to `Premium_AzureFrontDoor`.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSkuName string = 'Standard_AzureFrontDoor'


var rgName = '${assetPrefix}-rg'

module rg 'modules/rg.bicep' = {
  name: rgName
  params: {
    rgName: rgName
    location: location
  }
}

module storageAccounts 'modules/storageAccounts.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'storageAccounts'
  params: {
    assetPrefix: assetPrefix
    setDefaultActionDeny: frontDoorSkuName == 'Premium_AzureFrontDoor'? true : false
    skuName: storageSkuName
    storageAccountWebsiteContainerName: storageAccountWebsiteContainerName
    storageAccountWebsiteLocations: storageAccountWebsiteLocations
  }
}

module frontDoor 'modules/frontdoor.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'frontdoor'
  params: {
    frontDoorSkuName: frontDoorSkuName
    assetPrefix: assetPrefix
    frontDoorSettings: storageAccounts.outputs.storageSettings
  }
  dependsOn: [ 
    storageAccounts 
  ]
}
