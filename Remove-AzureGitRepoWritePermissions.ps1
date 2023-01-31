[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $OrgName,

    [Parameter(Mandatory = $true)]
    [string]
    $ProjectName,

    [Parameter(Mandatory = $true)]
    [string]
    $RepoName,

    [Parameter(Mandatory = $false)]
    [switch]
    $Confirm
)

$WritePermissions = @(
    "GenericContribute", 
    "ForcePush",
    "CreateBranch",
    "CreateTag",
    "ManageNote",
    "PolicyExempt",
    "PullRequestContribute",
    "PullRequestBypassPolicy"
)

function RemoveWritePermissionsFromAcls($acls, $gitSecActions)
{
    foreach ($acl in $acls)
    {
        foreach ($ace in $acl.acesDictionary.PSObject.Properties)
        {
            RemovePermissionFromAce $ace $WritePermissions $gitSecActions
        }
    }
}

function RemovePermissionFromAce($inputAce, $removeActionNames, $actions)
{
    $removeActions = $actions | Where-Object { $removeActionNames.Contains($_.name) }
    $removeActionBits = 0
    $removeActions | ForEach-Object { $removeActionBits = $_.bit -bor $removeActionBits }
    $removeActionBitsNeg = -bnot $removeActionBits

    $inputAce.Value.allow = $inputAce.Value.allow -band $removeActionBitsNeg
    $inputAce.Value.deny = $inputAce.Value.deny -bor $removeActionBits
}

function SetGitRepoAcls($orgName, $securityNamespaceId, $acls)
{
    foreach ($acl in $acls)
    {
        SetGitRepoAcl $orgName $securityNamespaceId $acl
    }
}

function SetGitRepoAcl($orgName, $securityNamespaceId, $acl)
{
    $requestUrl = "https://dev.azure.com/$orgName/_apis/accesscontrollists/$($securityNamespaceId)?api-version=7.1-preview.1"
    & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" $requestUrl "POST" $acl
}


# Begin of main script

$gitSecNamespace = & "$PSScriptRoot\Helpers\Get-RepoSecurityNamespace.ps1" -OrgName $OrgName
if ($null -eq $gitSecNamespace) 
{
    Write-Error "Git repos security namespace not found found for org $OrgName"
    exit 1
}

$gitRepoId = & "$PSScriptRoot\Helpers\Get-RepoId.ps1" -OrgName $OrgName -ProjectName $ProjectName -RepoName $RepoName
if ($null -eq $gitRepoId) 
{
    Write-Error "Git repos id namespace not found for org $OrgName project $ProjectName repo $RepoName"
    exit 2
}

Write-Host "Removing write permissions for org: $OrgName, project: $ProjectName, repo: $RepoName"
Write-Host

Write-Host "Original permission values"
Write-Host "--------------------------"
$repoAcls = & "$PSScriptRoot\Helpers\Get-RepoPermissions.ps1" -OrgName $OrgName -GitSecNamespace $gitSecNamespace -GitRepoId $gitRepoId
$identitiesCache = @{}
& "$PSScriptRoot\Helpers\Show-RepoPermissions.ps1" -OrgName $OrgName -GitSecNamespace $gitSecNamespace -Acls $repoAcls -IdentitiesCache $identitiesCache
Write-Host

Write-Host "Removing the following permissions from all ACEs in the repo: $WritePermissions"
if ($Confirm.IsPresent -eq $false)
{
    $confirmation = Read-Host "Do you want to continue?`n[Y] Yes  [N] No  (default is ""Y"")"
    if ($confirmation -eq "n") 
    {
        exit 0
    }
}
RemoveWritePermissionsFromAcls $repoAcls $gitSecNamespace.actions  
SetGitRepoAcls $OrgName $gitSecNamespace.namespaceId $repoAcls
Start-Sleep 2  # Give API time to persist values before reading them back
Write-Host

Write-Host "Updated permission values"
Write-Host "-------------------------"
$repoAclsFinal = & "$PSScriptRoot\Helpers\Get-RepoPermissions.ps1" -OrgName $OrgName -GitSecNamespace $gitSecNamespace -GitRepoId $gitRepoId
& "$PSScriptRoot\Helpers\Show-RepoPermissions.ps1" -OrgName $OrgName -GitSecNamespace $gitSecNamespace -Acls $repoAclsFinal -IdentitiesCache $identitiesCache
Write-Host
