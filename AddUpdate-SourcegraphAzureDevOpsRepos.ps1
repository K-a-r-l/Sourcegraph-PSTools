function Get-CodeHosts
{
    Param (
        [String]$BaseUri,
        [String]$ApiToken
    )
    
    <#
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
    
    ","variables":{"first":99999,"after":null}}
'@

    #Replacing newlines with \n so it will work in a web request
    $body = $body -Replace "`n", "\n"
    #>

    #When running this in Azure functions it seems to have problems with the here-string. So including the collapsed version instead
    $body = '{"query":"\n        query ExternalServices($first: Int, $after: String, $namespace: ID) {\n            externalServices(first: $first, after: $after, namespace: $namespace) {\n                nodes {\n                    ...ListExternalServiceFields\n                }\n                totalCount\n                pageInfo {\n                    endCursor\n                    hasNextPage\n                }\n            }\n        }\n    \n        fragment ListExternalServiceFields on ExternalService {\n            id\n            kind\n            displayName\n            config\n            repoCount\n        }\n    \n    ","variables":{"first":99999,"after":null}}'

    #Write-Output "URI: $BaseUri/.api/graphql?ExternalServices"
    #Write-Output "APIToken: $ApiToken"
    #Write-Output "Body: $ApiToken"

    try
    {
        $response = Invoke-RestMethod -uri "$BaseUri/.api/graphql?ExternalServices" -Header @{Authorization = "token $ApiToken"} -Method POST -Body $body -ContentType 'application/json; charset=utf-8'
    }
    catch
    {
        Write-Error "Error getting code hosts from SourceGraph - $BaseUri"
        Write-Error "| $($_.Exception.Message.ToString()) |"
    }
    return $response.data.externalServices.nodes
}


function Add-CodeHost
{
    Param (
        [String]$BaseUri,
        [String]$ApiToken,
        [String]$Name,
        [PSCustomObject]$Config
    )

    <#
    $body = @'
    {"query":"
            mutation AddExternalService($input: AddExternalServiceInput!) {
                addExternalService(input: $input) {
                    ...ExternalServiceFields
                }
            }
            
    fragment ExternalServiceFields on ExternalService {
        id
        kind
        displayName
        config
        warning
    }

        ","variables":{"input":{"displayName":"REPLACE-DISPLAYNAME","config":"REPLACE-CONFIG","kind":"OTHER"}}}
'@
    $body = $body -replace "`n","\n"
    #>

    #When running this in Azure functions it seems to have problems with the here-string above. So including the collapsed version instead
    $body = '{"query":"\n            mutation AddExternalService($input: AddExternalServiceInput!) {\n                addExternalService(input: $input) {\n                    ...ExternalServiceFields\n                }\n            }\n            \n    fragment ExternalServiceFields on ExternalService {\n        id\n        kind\n        displayName\n        config\n        warning\n    }\n\n        ","variables":{"input":{"displayName":"REPLACE-DISPLAYNAME","config":"REPLACE-CONFIG","kind":"OTHER"}}}'
    
    #Config is JSON being passed as a string, so minimize and escape quotes
    $configStr = $Config | ConvertTo-Json -Compress 
    $configStr = $configStr -Replace '"','\"'

    $body = $body -replace "REPLACE-DISPLAYNAME",$Name  
    $body = $body -replace "REPLACE-CONFIG", $configStr

    try
    {
        $response = Invoke-RestMethod -uri "$BaseUri/.api/graphql?AddExternalService" -Header @{Authorization = "token $ApiToken"} -Method POST -Body $body -ContentType 'application/json; charset=utf-8'
    }
    catch
    {
        Write-Error "Error adding CodeHost Name $Name "
        Write-Error $_.Exception.Message
        #return [PSCustomObject]@{"succeeded" = $false; "result" = $_.Exception.Message }    
    }

    #return [PSCustomObject]@{"succeeded" = $true; "result" = $response }
}

function Update-CodeHost
{
    Param (
        [String]$BaseUri,
        [String]$ApiToken,
        [String]$Name,
        [String]$Id,
        [PSCustomObject]$Config
    )

    <#
    $body = @'
    {"query":"
                mutation UpdateExternalService($input: UpdateExternalServiceInput!) {
                    updateExternalService(input: $input) {
                        ...ExternalServiceFields
                    }
                }
                
        fragment ExternalServiceFields on ExternalService {
            id
            kind
            displayName
            config
            warning
            repoCount
        }
    
            ","variables":{"input":{"__typename":"ExternalService","id":"REPLACE-ID","kind":"OTHER","displayName":"REPLACE-DISPLAYNAME","config":"REPLACE-CONFIG","warning":null}}}
'@

    $body = $body -replace "`n","\n"
    #>

    #When running this in Azure functions it seems to have problems with the here-string above. So including the collapsed version instead
    $body = '{"query":"\n                mutation UpdateExternalService($input: UpdateExternalServiceInput!) {\n                    updateExternalService(input: $input) {\n                        ...ExternalServiceFields\n                    }\n                }\n                \n        fragment ExternalServiceFields on ExternalService {\n            id\n            kind\n            displayName\n            config\n            warning\n            repoCount\n        }\n    \n            ","variables":{"input":{"__typename":"ExternalService","id":"REPLACE-ID","kind":"OTHER","displayName":"REPLACE-DISPLAYNAME","config":"REPLACE-CONFIG","warning":null}}}'

    #Config is JSON being passed as a string, so minimize and escape quotes
    $configStr = $Config | ConvertTo-Json -Compress 
    $configStr = $configStr -Replace '"','\"'
    $body = $body -Replace "REPLACE-ID", $Id
    $body = $body -replace "REPLACE-DISPLAYNAME", $Name
    $body = $body -replace "REPLACE-CONFIG", $configStr    
    
    try {
        $response = Invoke-RestMethod -uri "$BaseUri/.api/graphql?UpdateExternalService" -Header @{Authorization = "token $ApiToken"} -Method POST -Body $body -ContentType 'application/json; charset=utf-8'
        $response.data.updateExternalService
    }
    catch
    {
        Write-Error "Error updating CodeHost Name $Name, Id: $Id "
        Write-Error $_.Exception.Message
        #[PSCustomObject]@{"succeeded" = $false; "result" = $_.Exception.Message }    
    }
    
    #return [PSCustomObject]@{"succeeded" = $true; "result" = $response }
}

# Region InstallPrereqModule

# Requires VSTeam module, developed by Microsoft staff (Azure CTO)
# https://github.com/MethodsAndPractices/vsteam
#To list all the possible commands in the modile run this command:
## Get-Command | ? {$_.Source -match "VSTeam"}

if($null -eq (Get-Module -List -Name VSTeam))
{
    Install-Module -Name VSTeam -Repository PSGallery -AcceptLicense -Force
}
#EndRegion

#Region Settings
##Get settings from Azure Function App Application settings
$ADOPersonalAccessToken = $env:ADOPersonalAccessToken
$ADOCodeHostNamePrefix = $env:ADOCodeHostNamePrefix
$ADOOrgList = ($env:ADOOrgList) -Split ","

$SourceGraphBaseUri = $env:SourceGraphBaseUri
$SourceGraphAPIToken = $env:SourceGraphAPIToken


$ExcludedProjects = $env:ExcludedProjects
$ExcludedProjects = $ExcludedProjects -Split ","
#Joining with | to make regex pattern
$ExcludedProjects = $ExcludedProjects | Join-String -Separator "|"

#EndRegion

#It's 100 by default, but ADO orgs can have up to 1000 projects. Super useful default...
Set-VSTeamDefaultProjectCount 2000

$sourceGraphCodeHosts = Get-CodeHosts -BaseUri $SourceGraphBaseUri -ApiToken $SourceGraphAPIToken
if($null -eq $sourceGraphCodeHosts)
{
    Write-Error "No SourceGraph codehosts found, existing"
    exit
}


foreach($org in $ADOOrgList)
{
    Write-Output "Processing ADO Org: $org"
    try
    {
        Set-VSTeamAccount -Account $org -PersonalAccessToken $ADOPersonalAccessToken -ErrorAction Stop
        $projects = Get-VSTeamProject -ErrorAction Stop
    } catch
    {
        Write-Output "Error getting projects for org: $org"
        Write-Output $_.Exception.Message
        continue
    }

    foreach($project in $projects)
    {
        
        if($project.Name -Match $ExcludedProjects)
        {
            Write-Host -ForegroundColor DarkMagenta "SKIPPING $($project.Name)"
            continue
        }
        #Note: This only get Git Repos, not TFS ones, but that's all I cared about
        try
        {
            $repos =  Get-VSTeamGitRepository -ProjectName $project.Name -ErrorAction Stop
        }
        catch
        {
            Write-Output "Error getting repos from org: $org, project: $($project.Name)"
            Write-Output $_.Exception.Message
            continue
        }
        
        if($repos.count -gt 0)
        {
            
            $repoList = New-Object -Type System.Collections.Generic.List[String]

            foreach($repo in $repos)
            {
                $repoList.Add($repo.Name)
            }
            
            $sourceGraphObject = [PSCustomObject]@{
                "url" = "https://$ADOPersonalAccessToken@dev.azure.com/$org/$([System.Uri]::EscapeUriString($project.Name))/_git/"
                "repos" = $repoList
            }
           
            $existingCodeHost = $sourceGraphCodeHosts | Where-Object { $_.displayName -eq "$($ADOCodeHostNamePrefix)_$($org)_$($project.Name)" }

            if(!$existingCodeHost)
            {
                Write-Output "Org: $org, project: $($project.Name). Code host doesn't exist, creating"
                Write-Output "ADDING"
                Add-CodeHost -BaseUri $SourceGraphBaseUri -ApiToken $SourceGraphAPIToken -Name "$($ADOCodeHostNamePrefix)_$($org)_$($project.Name)" -Config $sourceGraphObject
            }

            #Yeah this comparison is kind of dirty, but hey ho
            #Converts the sourceGraphObject to a minified json string, converts the existing config from a string, to an object, and back to a minified json string
            # then compares. Trying to make sure no formatting/white space causes issues with comparison
            elseif(($sourceGraphObject | ConvertTo-Json -Compress) -ne ($existingCodeHost.config | ConvertFrom-Json | ConvertTo-Json -Compress)  )
            {
                Write-Output "Org: $org, project: $($project.Name). Code host exists, repo config doesn't match, updating"
                Write-Output "UPDATING"
                Update-CodeHost -BaseUri $SourceGraphBaseUri -ApiToken $SourceGraphAPIToken -Name ($existingCodeHost.displayName) -Id ($existingCodeHost.id)  -Config $sourceGraphObject
            } 
            else 
            {
                Write-Output "Org: $org, project: $($project.Name). Code host exists, repo config matches, no action"
                Write-Output "NOTHING"
                # Existing, no update required
            }
        }
    }
}

Write-Output "Finished!"