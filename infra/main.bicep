targetScope = 'subscription'

//
// BASIC PARAMETERS
//
@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources (filtered on available regions for Azure Open AI Service).')
@allowed([
  'uaenorth'
  'southafricanorth'
  'westeurope'
  'southcentralus'
  'australiaeast'
  'canadaeast'
  'eastus'
  'eastus2'
  'francecentral'
  'japaneast'
  'northcentralus'
  'swedencentral'
  'switzerlandnorth'
  'uksouth'
])
param location string

@description('Tags to be applied to resources.')
param tags object

//
// RESOURCE NAMES - Assign custom names to different provisioned services
//
@description('Name of the resource group. Leave blank to use default naming conventions.')
param resourceGroupName string

@description('Name of the Cosmos DB account resource. Leave blank to use default naming conventions.')
param cosmosDbAccountName string

@description('Name of the Azure Language service. Leave blank to use default naming conventions.')
param languageServiceName string

@description('Name of the Azure Content Safety service. Leave blank to use default naming conventions.')
param aiContentSafetyName string

//
// NETWORKING PARAMETERS - Network configuration and access controls
//
@description('Name of the Virtual Network. Leave blank to use default naming conventions.')
param vnetName string

@description('Use an existing Virtual Network instead of creating a new one.')
param useExistingVnet bool

@description('Resource group containing the existing VNet (only used when useExistingVnet is true).')
param existingVnetRG string

@description('Subnet name for Private Endpoints in the VNet. Leave blank to use default naming conventions.')
param cosmosPrivateEndpointSubnetName string

@description('Cosmos DB throughput in Request Units (RUs).')
param cosmosDbRUs int

param languageApiPrivateEndpointSubnetName string
param contentSafetyPrivateEndpointSubnetName string

// DNS ZONE PARAMETERS - DNS zone configuration for private endpoints (for use with existing VNet)
@description('Resource group containing the DNS zones (only used with existing VNet).')
param dnsZoneRG string

@description('Subscription ID containing the DNS zones (only used with existing VNet).')
param dnsSubscriptionId string

@description('Cosmos DB private endpoint name. Leave blank to use default naming conventions.')
param cosmosDbPrivateEndpointName string

@description('Name of the Azure Language service private endpoint. Leave blank to use default naming conventions.')
param languageServicePrivateEndpointName string

@description('Name of the Azure Content Safety service private endpoint. Leave blank to use default naming conventions.')
param aiContentSafetyPrivateEndpointName string

@description('Cosmos DB public network access.')
@allowed([ 'Enabled', 'Disabled' ])
param cosmosDbPublicAccess string

@description('Azure Language service external network access.')
@allowed([ 'Enabled', 'Disabled' ])
param languageServiceExternalNetworkAccess string

@description('Azure Content Safety external network access.')
@allowed([ 'Enabled', 'Disabled' ])
param aiContentSafetyExternalNetworkAccess string

@description('Azure Language service SKU name.')
param languageServiceSkuName string

@description('Azure Content Safety service SKU name.')
param aiContentSafetySkuName string

// Load abbreviations from JSON file
var abbrs = loadJsonContent('./abbreviations.json')

// Generate a unique token for resources
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

var cosmosDbPrivateDnsZoneName = 'privatelink.documents.azure.com'
var aiCogntiveServicesDnsZoneName = 'privatelink.cognitiveservices.azure.com'

module vnetExisting './modules/networking/vnet-existing.bicep' = if (useExistingVnet) {
  name: 'vnetExisting'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: vnetName
    cosmosPrivateEndpointSubnetName: cosmosPrivateEndpointSubnetName
    languageApiPrivateEndpointSubnetName: languageApiPrivateEndpointSubnetName
    contentSafetyPrivateEndpointSubnetName: contentSafetyPrivateEndpointSubnetName
    vnetRG: existingVnetRG
  }
}

module contentSafety 'modules/ai/cognitiveservices.bicep' = {
  name: 'ai-content-safety'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: !empty(aiContentSafetyName) ? aiContentSafetyName : '${abbrs.cognitiveServicesAccounts}consafety-${resourceToken}'
    location: location
    tags: tags
    kind: 'ContentSafety'
    vNetName: vnetExisting.outputs.vnetName
    vNetLocation: vnetExisting.outputs.location
    privateEndpointSubnetName: vnetExisting.outputs.contentSafetyPrivateEndpointSubnetName
    aiPrivateEndpointName: !empty(aiContentSafetyPrivateEndpointName) ? aiContentSafetyPrivateEndpointName : '${abbrs.cognitiveServicesAccounts}consafety-pe-${resourceToken}'
    publicNetworkAccess: aiContentSafetyExternalNetworkAccess
    openAiDnsZoneName: aiCogntiveServicesDnsZoneName
    sku: {
      name: aiContentSafetySkuName
    }
    vNetRG: vnetExisting.outputs.vnetRG
    dnsZoneRG: dnsZoneRG
    dnsSubscriptionId: dnsSubscriptionId
  }
  dependsOn: [
    vnetExisting
  ]
}

module languageService 'modules/ai/cognitiveservices.bicep' = {
  name: 'ai-language-service'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: !empty(languageServiceName) ? languageServiceName : '${abbrs.cognitiveServicesAccounts}language-${resourceToken}'
    location: location
    tags: tags
    kind: 'TextAnalytics'
    vNetName: vnetExisting.outputs.vnetName
    vNetLocation: vnetExisting.outputs.location
    privateEndpointSubnetName: vnetExisting.outputs.languageApiPrivateEndpointSubnetName
    aiPrivateEndpointName: !empty(languageServicePrivateEndpointName) ? languageServicePrivateEndpointName : '${abbrs.cognitiveServicesAccounts}language-pe-${resourceToken}'
    publicNetworkAccess: languageServiceExternalNetworkAccess
    openAiDnsZoneName: aiCogntiveServicesDnsZoneName
    sku: {
      name: languageServiceSkuName
    }
    vNetRG: vnetExisting.outputs.vnetRG
    dnsZoneRG: dnsZoneRG
    dnsSubscriptionId: dnsSubscriptionId
  }
  dependsOn: [
    vnetExisting
  ]
}

module cosmosDb './modules/cosmos-db/cosmos-db.bicep' = {
  name: 'cosmos-db'
  scope: resourceGroup(resourceGroupName)
  params: {
    accountName: !empty(cosmosDbAccountName) ? cosmosDbAccountName : '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
    location: location
    tags: tags
    vNetName: vnetExisting.outputs.vnetName
    cosmosDnsZoneName: cosmosDbPrivateDnsZoneName
    cosmosPrivateEndpointName: !empty(cosmosDbPrivateEndpointName) ? cosmosDbPrivateEndpointName : '${abbrs.documentDBDatabaseAccounts}pe-${resourceToken}'
    privateEndpointSubnetName: vnetExisting.outputs.cosmosPrivateEndpointSubnetName
    vNetRG: vnetExisting.outputs.vnetRG
    dnsZoneRG: dnsZoneRG
    dnsSubscriptionId: dnsSubscriptionId
    throughput: cosmosDbRUs
    publicAccess: cosmosDbPublicAccess
  }
  dependsOn: [
    vnetExisting
  ]
}
