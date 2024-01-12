param location string = resourceGroup().location


resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: 'appInsights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}


output connectionString string = appInsights.properties.ConnectionString
