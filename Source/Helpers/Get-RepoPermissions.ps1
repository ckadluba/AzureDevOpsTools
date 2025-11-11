[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $ServerUrl,

    [Parameter(Mandatory)]
    [string]
    $OrgName,

    [Parameter(Mandatory)]
    $GitSecNamespace,

    [Parameter(Mandatory)]
    [string]
    $GitRepoId
)


# Begin of main script

$acls = $null

$requestUrl = "$ServerUrl/$OrgName/_apis/accesscontrollists/$($GitSecNamespace.namespaceId)?includeExtendedInfo=True&api-version=6.0"
$allRepoAclsResponse = $null
$allRepoAclsResponse = & "$PSScriptRoot\Call-ApiWithToken.ps1" -Url $requestUrl
$allRepoAcls = $allRepoAclsResponse.value
$acls = $allRepoAcls | Where-Object { $_.token.StartsWith("repoV2") -and $_.token.EndsWith($GitRepoId) }

if ($null -eq $acls)
{
    Write-Warning "No ACLs found for git repo $GitRepoId"
}

$acls
