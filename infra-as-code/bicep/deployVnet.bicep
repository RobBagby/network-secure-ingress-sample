targetScope = 'resourceGroup'

@description('This is the prefix for each Azure resource name')
param assetPrefix string = 'bagbyfd'

@description('The location to deploy the vnet, jumpbox and bastion. Default: resourceGroup().location')
param location string = resourceGroup().location

@description('The locations of the storage accounts that contain the websites.')
param storageAccountWebsiteLocations array = [
  'eastus'
  'westus3'
]

@description('The admin user name for the jumpbox')
param vmadmin string = 'azureuser'

@description('The ssh public key for the jumpbox')
@secure()
param jumpboxPublicSshKey string

@description('Service principal object id. This SP will be given Storage Blob Data Contributor Role Assignment. It can be used to update the website.')
@secure()
param principalId string = ''

var resourceGroupName = resourceGroup().name
var bastionSubnetName = 'AzureBastionSubnet'
var jumpboxSubnetName = 'JumpboxSubnet'
var firewallSubnetName = 'FirewallSubnet'
var privateEndpointsSubnetName = 'PrivateEndpointsSubnet'

var roleStorageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

var vnetSettings = {
  name: '${assetPrefix}-vnet'
  location: location
  addressPrefixes: [
    '10.0.0.0/16'
  ]
  subnets: [
    {
      name: 'default'
      addressPrefix: '10.0.0.0/24'
    }
    {
      name: firewallSubnetName
      addressPrefix: '10.0.1.0/24'
    }
    {
      name: privateEndpointsSubnetName
      addressPrefix: '10.0.2.0/24'
    }
    {
      name: jumpboxSubnetName
      addressPrefix: '10.0.3.0/28'
    }
    {
      name: bastionSubnetName
      addressPrefix: '10.0.4.0/28'
    }
  ]
}

module vnet 'modules/vnet.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: vnetSettings.name
  params: {
    vNetSettings: vnetSettings
  }
}

var bastionSubnetId = '${vnet.outputs.vnetId}/subnets/${bastionSubnetName}'
var privateEndpointsSubnetId = '${vnet.outputs.vnetId}/subnets/${privateEndpointsSubnetName}'
var jumpboxSubnetId = '${vnet.outputs.vnetId}/subnets/${jumpboxSubnetName}'

module storageAccounts 'modules/storageAccountsExisting.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'storageAccounts'
  params: {
    assetPrefix: assetPrefix
    storageAccountWebsiteLocations: storageAccountWebsiteLocations
  }
}

module bastion 'modules/bastion.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'bastion'
  params: {
    name: '${assetPrefix}-bastion'
    location: location
    bastionSubnetId: bastionSubnetId
  }
  dependsOn: [
    vnet
  ]
}

module jumpbox 'modules/jumpbox.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'jumpbox'
  params: {
    name: '${assetPrefix}-jumpbox'
    location: location
    jumpboxSubnetId: jumpboxSubnetId
    vmadmin: vmadmin
    publicKey: jumpboxPublicSshKey
  }
  dependsOn: [
    vnet
  ]
}

module storagePe 'modules/storagePrivateEndpoints.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'storagePe'
  params: {
    name: '${assetPrefix}-jumpbox'
    location: location
    subnetId: privateEndpointsSubnetId
    storageSettings: storageAccounts.outputs.storageSettings
    vnetId: vnet.outputs.vnetId
  }
  dependsOn: [
    vnet
    storageAccounts
  ]
}

module storageAccountRoleAssignment 'modules/storageAccountRoleAssignment.bicep' = {
  name: 'storageAccountRoleAssignment'
  scope: resourceGroup(resourceGroupName)
  params: {
    principalId: principalId
    roleDefinitionResourceId: roleStorageBlobDataContributor
  }
}
