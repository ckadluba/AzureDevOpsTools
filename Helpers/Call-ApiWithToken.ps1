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
    $Body = $null
)


# Begin of main script

if ($null -eq $env:AzureDevOpsTools_PAT)
{
    throw "Please set the environment variable AzureDevOpsTools_PAT to a valid PAT token with adequate permissions."
}

$authString = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":" + $env:AzureDevOpsTools_PAT))

$requestArgs = @{
    Method      = $Method
    Uri         = $Url
    Headers     = @{ Authorization = $authString }
}

if ($null -ne $Body)
{
    $requestArgs.Body        = $Body | ConvertTo-Json -Depth 10
    $requestArgs.ContentType = "application/json"
}

Invoke-RestMethod @requestArgs
