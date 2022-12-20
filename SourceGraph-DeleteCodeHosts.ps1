function Get-CodeHosts
{
    Param (
        #Mandatory
        [String]$BaseUri,
        [String]$ApiToken
    )
    
   $body = @'
    {"query":"
        query ExternalServices($first: Int, $after: String, $namespace: ID) {
            externalServices(first: $first, after: $after, namespace: $namespace) {
                nodes {
                    ...ListExternalServiceFields
                }
                totalCount
                pageInfo {
                    endCursor
                    hasNextPage
                }
            }
        }
    
        fragment ListExternalServiceFields on ExternalService {
            id
            kind
            displayName
            config
            repoCount
        }
    
    ","variables":{"first":9999,"after":null}}
'@

    #Replacing newlines with \n so it will work in a web request
    $body = $body -Replace "`n", "\n"

    #When running this in Azure functions, it seems to have problems with the here-string. So including the collapsed version here
    $body = '{"query":"\n        query ExternalServices($first: Int, $after: String, $namespace: ID) {\n            externalServices(first: $first, after: $after, namespace: $namespace) {\n                nodes {\n                    ...ListExternalServiceFields\n                }\n                totalCount\n                pageInfo {\n                    endCursor\n                    hasNextPage\n                }\n            }\n        }\n    \n        fragment ListExternalServiceFields on ExternalService {\n            id\n            kind\n            displayName\n            config\n            repoCount\n        }\n    \n    ","variables":{"first":9999,"after":null}}'

    try
    {
        $response = Invoke-RestMethod -uri "$BaseUri/.api/graphql?ExternalServices" -Header @{Authorization = "token $ApiToken"} -Method POST -Body $body  -ContentType 'application/json; charset=utf-8'
    }
    catch
    {
        # Add some error handling here
    }
    return $response.data.externalServices.nodes
}

function Remove-CodeHost
{
    Param (
        #Mandatory
        [String]$BaseUri,
        [String]$ApiToken,
        [String]$Id
    )
    
    $deleteBody = '{"query":"\n            mutation DeleteExternalService($externalService: ID!) {\n                deleteExternalService(externalService: $externalService) {\n                    alwaysNil\n                }\n            }\n        ","variables":{"externalService":"REPLACE-ID"}}""'

    $deleteBody = $deleteBody -Replace "REPLACE-ID", $Id

    try
    {
        $response = Invoke-RestMethod -uri "$BaseUri/.api/graphql?DeleteExternalService" -Header @{Authorization = "token $ApiToken"} -Method POST -Body $deleteBody  -ContentType 'application/json; charset=utf-8'
        $response
    }
    catch
    {
        # Add some error handling here
    }
    return
}

$SourceGraphBaseUri = "https://sourcegraph.example.com"
$SourceGraphAPIToken = "<APITokenHere>"      

$sourceGraphCodeHosts = Get-CodeHosts -BaseUri $SourceGraphBaseUri -ApiToken $SourceGraphAPIToken

$codehostsToDelete = $sourceGraphCodeHosts | Where-Object {$_.displayName -match "<DELETEFILTER>" }
foreach($codehost in $codehostsToDelete)
{
    Remove-CodeHost -BaseUri $SourceGraphBaseUri -ApiToken $SourceGraphAPIToken -Id $codehost.id
}