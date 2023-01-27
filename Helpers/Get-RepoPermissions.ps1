[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $OrgName,

    [Parameter(Mandatory=$true)]
    $GitSecNamespace,

    [Parameter(Mandatory=$true)]
    [string]
    $GitRepoId
)


# Begin of main script

$acls = $null

$requestUrl = "https://dev.azure.com/$OrgName/_apis/accesscontrollists/$($GitSecNamespace.namespaceId)?includeExtendedInfo=True&api-version=6.0"
$allRepoAclsResponse = $null
$allRepoAclsResponse = & "$PSScriptRoot\Call-ApiWithToken.ps1" $requestUrl
$allRepoAcls = $allRepoAclsResponse.value
$acls = $allRepoAcls | Where-Object { $_.token.StartsWith("repoV2") -and $_.token.EndsWith($GitRepoId) }

if ($null -eq $acls) 
{
    Write-Host "No ACLs found for git repo $GitRepoId"
}

$acls
