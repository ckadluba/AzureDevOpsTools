[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $ServerUrl,

    [Parameter(Mandatory)]
    [string]
    $OrgName,

    [Parameter(Mandatory)]
    [string]
    $ProjectName,

    [Parameter(Mandatory)]
    [string]
    $RepoName,

    [Parameter()]
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
            RemovePermissionFromAce -inputAce $ace -removeActionNames $WritePermissions -actions $gitSecActions
        }
    }
}

function RemovePermissionFromAce
{
    param (
        [Parameter(Mandatory)]
        $inputAce,

        [Parameter(Mandatory)]
        $removeActionNames,

        [Parameter(Mandatory)]
        $actions
    )

    $removeActions = $actions | Where-Object { $removeActionNames.Contains($_.name) }
    $removeActionBits = 0
    $removeActions | ForEach-Object { $removeActionBits = $_.bit -bor $removeActionBits }
    $removeActionBitsNeg = -bnot $removeActionBits

    $inputAce.Value.allow = $inputAce.Value.allow -band $removeActionBitsNeg
    $inputAce.Value.deny = $inputAce.Value.deny -bor $removeActionBits
}

function SetGitRepoAcls
{
    param (
        [Parameter(Mandatory)]
        $orgName,

        [Parameter(Mandatory)]
        $securityNamespaceId,

        [Parameter(Mandatory)]
        $acls
    )

    foreach ($acl in $acls)
    {
        SetGitRepoAcl -orgName $orgName -securityNamespaceId $securityNamespaceId -acl $acl
    }
}

function SetGitRepoAcl
{
    param (
        [Parameter(Mandatory)]
        $orgName,

        [Parameter(Mandatory)]
        $securityNamespaceId,

        [Parameter(Mandatory)]
        $acl
    )

    $requestUrl = "https://dev.azure.com/$orgName/_apis/accesscontrollists/$($securityNamespaceId)?api-version=7.1-preview.1"
    $requestBody = @{
        "count" = 1
        "value" = @( $acl )
    }
    & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl -Method "POST" -Body $requestBody
}


# Begin of main script

$gitSecNamespace = & "$PSScriptRoot\Helpers\Get-RepoSecurityNamespace.ps1" -ServerUrl $ServerUrl -OrgName $OrgName
if ($null -eq $gitSecNamespace)
{
    Write-Error "Git repos security namespace not found found for org $OrgName"
    exit 1
}

$gitRepoId = & "$PSScriptRoot\Helpers\Get-RepoId.ps1" -ServerUrl $ServerUrl -OrgName $OrgName -ProjectName $ProjectName -RepoName $RepoName
if ($null -eq $gitRepoId)
{
    Write-Error "Git repos id namespace not found for org $OrgName project $ProjectName repo $RepoName"
    exit 2
}

Write-Host "Removing write permissions for org: $OrgName, project: $ProjectName, repo: $RepoName"
Write-Host

Write-Host "Original permission values"
Write-Host "--------------------------"
$repoAcls = & "$PSScriptRoot\Helpers\Get-RepoPermissions.ps1" -ServerUrl $ServerUrl -OrgName $OrgName -GitSecNamespace $gitSecNamespace -GitRepoId $gitRepoId
$identitiesCache = @{}
& "$PSScriptRoot\Helpers\Show-RepoPermissions.ps1" -ServerUrl $ServerUrl -OrgName $OrgName -GitSecNamespace $gitSecNamespace -Acls $repoAcls -IdentitiesCache $identitiesCache
Write-Host

Write-Host "Removing the following permissions from all ACEs in the repo: $WritePermissions"
if (-not $Confirm.IsPresent)
{
    $confirmation = Read-Host "Do you want to continue?`n[Y] Yes  [N] No  (default is ""N"")"
    if ($confirmation -ne "y")
    {
        exit 0
    }
}
RemoveWritePermissionsFromAcls $repoAcls $gitSecNamespace.actions
SetGitRepoAcls -orgName $OrgName -securityNamespaceId $gitSecNamespace.namespaceId -acls $repoAcls
Start-Sleep 2  # Give API time to persist values before reading them back
Write-Host

Write-Host "Updated permission values"
Write-Host "-------------------------"
$repoAclsFinal = & "$PSScriptRoot\Helpers\Get-RepoPermissions.ps1" -ServerUrl $ServerUrl -OrgName $OrgName -GitSecNamespace $gitSecNamespace -GitRepoId $gitRepoId
& "$PSScriptRoot\Helpers\Show-RepoPermissions.ps1" -ServerUrl $ServerUrl -OrgName $OrgName -GitSecNamespace $gitSecNamespace -Acls $repoAclsFinal -IdentitiesCache $identitiesCache
