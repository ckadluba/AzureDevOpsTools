[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $ServerUrl,

    [Parameter(Mandatory)]
    [string]
    $OrgName
)


# Begin of main script

$requestUrl = "$ServerUrl/$OrgName/_apis/securitynamespaces?api-version=6.0"
$allNamespacesResponse = & "$PSScriptRoot\Call-ApiWithToken.ps1" -Url $requestUrl
$allNamespacesResponse.value | Where-Object { $_.name -eq "Git Repositories" }
