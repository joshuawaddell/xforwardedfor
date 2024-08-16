// Parameters
//////////////////////////////////////////////////
@description('The array of Dns Cname Records')
param appServiceCnameRecords array

@description('The array of Dns Zone Records.')
param appServiceTxtRecords array

@description('The name of the Dns Zone.')
param dnsZoneName string

// Resource - Dns Zone -Cname Record
//////////////////////////////////////////////////
resource cnameRecord 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = [for (appServiceCnameRecord, i) in appServiceCnameRecords: {
  name: '${dnsZoneName}/${appServiceCnameRecord.name}'
  properties: {
    TTL: appServiceCnameRecord.ttl
    CNAMERecord: {
      cname: appServiceCnameRecord.cname
    }
  }
}]

// Resource - Dns Zone - Txt Record
//////////////////////////////////////////////////
resource txtRecord 'Microsoft.Network/dnsZones/TXT@2018-05-01' = [for (appServiceTxtRecord, i) in appServiceTxtRecords: {
	name: '${dnsZoneName}/${appServiceTxtRecord.name}'
	properties: {
		TTL: appServiceTxtRecord.ttl
		TXTRecords: [
			{
				value: [
					appServiceTxtRecord.value
				]
			}
		]
	}
}]
