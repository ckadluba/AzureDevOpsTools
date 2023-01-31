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
    $RepoName
)


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

Write-Host "Permissions for org: $OrgName, project: $ProjectName, repo: $RepoName"
Write-Host

$repoAcls = & "$PSScriptRoot\Helpers\Get-RepoPermissions.ps1" -OrgName $OrgName -GitSecNamespace $gitSecNamespace -GitRepoId $gitRepoId
& "$PSScriptRoot\Helpers\Show-RepoPermissions.ps1" -OrgName $OrgName -GitSecNamespace $gitSecNamespace -Acls $repoAcls
