[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $Url,

    [Parameter(Mandatory = $false)]
    [string]
    $Method = "GET",

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSObject]
    $Acl = $null
)


# Begin of main script

if ($null -eq $env:AzureGitRepoTools_PAT)
{
    throw "Please set the environment variable AzureGitRepoTools_PAT to a valid PAT token with Code: read and Security: manage permissions."
}

$authString = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":" + $env:AzureGitRepoTools_PAT))

$requestArgs = @{
    Method      = $Method
    Uri         = $Url
    Headers     = @{Authorization = $authString }
}

if ($null -ne $Acl)
{
    $requestBody = @{
        "count" = 1
        "value" = @( $Acl )
    }

    $requestArgs.Body        = $requestBody | ConvertTo-Json -Depth 6
    $requestArgs.ContentType = "application/json"
}

Invoke-RestMethod @requestArgs
