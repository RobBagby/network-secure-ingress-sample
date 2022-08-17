@description('The id of the principal to assign the role to')
param principalId string 

@description('The id of the existing role definition')
param roleDefinitionResourceId string

var principalType = 'ServicePrincipal'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(principalId, roleDefinitionResourceId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionResourceId)
    principalId: principalId
    principalType: principalType
  }
}
