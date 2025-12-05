param name string
param vnetRG string
// param apimSubnetName string
param cosmosPrivateEndpointSubnetName string
param languageApiPrivateEndpointSubnetName string 
param contentSafetyPrivateEndpointSubnetName string 
// param functionAppSubnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: name
  scope: resourceGroup(vnetRG)
}


resource cosmosPrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: cosmosPrivateEndpointSubnetName
  parent: virtualNetwork
}

resource languageApiPrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: languageApiPrivateEndpointSubnetName
  parent: virtualNetwork
}

resource contentSafetyPrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: contentSafetyPrivateEndpointSubnetName
  parent: virtualNetwork
}


output virtualNetworkId string = virtualNetwork.id
output vnetName string = virtualNetwork.name

output cosmosPrivateEndpointSubnetName string = cosmosPrivateEndpointSubnet.name
output cosmosPrivateEndpointSubnetId string = '${virtualNetwork.id}/subnets/${cosmosPrivateEndpointSubnetName}'

output languageApiPrivateEndpointSubnetName string = languageApiPrivateEndpointSubnet.name
output languageApiPrivateEndpointSubnetId string = '${virtualNetwork.id}/subnets/${languageApiPrivateEndpointSubnetName}'

output contentSafetyPrivateEndpointSubnetName string = contentSafetyPrivateEndpointSubnet.name
output contentSafetyPrivateEndpointSubnetId string = '${virtualNetwork.id}/subnets/${contentSafetyPrivateEndpointSubnetName}'

output location string = virtualNetwork.location
output vnetRG string = vnetRG
