[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $OrgName,

    [Parameter()]
    [string]
    $ProjectName = "",

    [Parameter()]
    [switch]
    $ExcludePermissions
)

function GetReposOfProject
{
    param (
        [Parameter(Mandatory)]
        [string]
        $orgName,

        [Parameter(Mandatory)]
        [string]
        $projectName,

        [Parameter(Mandatory)]
        $excludePermissions,

        [Parameter()]
        $gitSecNamespace
    )

    Write-Debug "Checking repos for org: $orgName, project: $projectName"

    $requestUrl = "https://dev.azure.com/$orgName/$projectName/_apis/git/repositories?includeLinks=true&includeAllUrls=true&includeHidden=true&api-version=7.0"
    $repos = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl

    foreach ($repo in $repos.value)
    {
        Write-Debug "Checking repo $($repo.name)"

        # Create return object with basic repo info
        $repoObj = New-Object -TypeName PSObject
        $repoObj | Add-Member -NotePropertyName "Name" -NotePropertyValue $repo.name
        $repoObj | Add-Member -NotePropertyName "WebUrl" -NotePropertyValue $repo.webUrl
        $repoObj | Add-Member -NotePropertyName "IsDisabled" -NotePropertyValue $repo.isDisabled
        $repoObj | Add-Member -NotePropertyName "IsMaintenance" -NotePropertyValue $repo.isDisabled

        $gitRepoId = & "$PSScriptRoot\Helpers\Get-RepoId.ps1" -OrgName $orgName -ProjectName $projectName -RepoName $repo.name
        if ($null -eq $gitRepoId)
        {
            Write-Error "Git repo id not found for org $OrgName project $ProjectName repo $($repo.name)"
        }
        else
        {
            Write-Debug "Getting last commit"
            AddLastCommitInfo -orgName $orgName -projectName $projectName -gitRepoId $gitRepoId -repoObj $repoObj

            if (-not $excludePermissions.IsPresent)
            {
                Write-Debug "Getting permissions"
                AddPermissionsInfo -orgName $orgName -gitSecNamespace $gitSecNamespace -gitRepoId $gitRepoId -repoObj $repoObj
            }
        }

        # Add project info
        $repoObj | Add-Member -NotePropertyName "ProjectName" -NotePropertyValue $repo.project.name
        $repoObj | Add-Member -NotePropertyName "ProjectUrl" -NotePropertyValue $repo.project.url
        $repoObj | Add-Member -NotePropertyName "ProjectVisibility" -NotePropertyValue $repo.project.visibility

        $repoObj
    }
}

function AddLastCommitInfo
{
    param (
        [Parameter(Mandatory)]
        [string]
        $orgName,

        [Parameter(Mandatory)]
        [string]
        $projectName,

        [Parameter(Mandatory)]
        [string]
        $gitRepoId,

        [Parameter(Mandatory)]
        $repoObj
    )

    $requestUrl = "https://dev.azure.com/$orgName/$projectName/_apis/git/repositories/$gitRepoId/commits?api-version=6.1-preview.1"
    $commitInfos = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl
    if ($null -eq $commitInfos)
    {
        return
    }
    $lastCommitId = $commitInfos.value.commitId | Select-Object -first 1

    $requestUrl = "https://dev.azure.com/$orgName/$projectName/_apis/git/repositories/$gitRepoId/commits/$($lastCommitId)?api-version=6.0-preview.1"
    $lastCommitInfo = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl
    if ($null -eq $lastCommitInfo)
    {
        return
    }

    $repoObj | Add-Member -NotePropertyName "LastCommitId" -NotePropertyValue $lastCommitInfo.commitid
    $repoObj | Add-Member -NotePropertyName "LastCommitAuthorName" -NotePropertyValue $lastCommitInfo.author.name
    $repoObj | Add-Member -NotePropertyName "LastCommitAuthorEmail" -NotePropertyValue $lastCommitInfo.author.email
    $repoObj | Add-Member -NotePropertyName "LastCommitDate" -NotePropertyValue $lastCommitInfo.push.date
    $repoObj | Add-Member -NotePropertyName "LastCommitComment" -NotePropertyValue $lastCommitInfo.comment
}

function AddPermissionsInfo
{
    param (
        [Parameter(Mandatory)]
        [string]
        $orgName,

        [Parameter(Mandatory)]
        $gitSecNamespace,

        [Parameter(Mandatory)]
        [string]
        $gitRepoId,

        [Parameter(Mandatory)]
        $repoObj
    )

    $acls = & "$PSScriptRoot\Helpers\Get-RepoPermissions.ps1" -OrgName $orgName -GitSecNamespace $gitSecNamespace -GitRepoId $gitRepoId
    if ($null -eq $acls)
    {
        return
    }

    $repoObj | Add-Member -NotePropertyName "AclsInheritPermissions" -NotePropertyValue $acls.inheritPermissions

    $combinedAllowDenySum = 0
    foreach ($ace in $acls.acesDictionary.PSObject.Properties)
    {
        $combinedAllowDeny = $ace.value.extendedInfo.effectiveAllow -band (-bnot $ace.value.extendedInfo.effectiveDeny)
        $combinedAllowDenySum = $combinedAllowDenySum -bor $combinedAllowDeny
    }
    $combinedAllowDenySumString = & "$PSScriptRoot\Helpers\ConvertTo-StringBinary.ps1" -Bits $combinedAllowDenySum
    $repoObj | Add-Member -NotePropertyName "AclsCombinedAllowDenySum" -NotePropertyValue "0b$combinedAllowDenySumString"

    AddAclPermissionProperties -actions $gitSecNamespace.actions -combinedSum $combinedAllowDenySum
}

function AddAclPermissionProperties
{
    param (
        [Parameter(Mandatory)]
        $actions,

        [Parameter(Mandatory)]
        $combinedSum
    )

    foreach ($action in $actions)
    {
        $actionAllowed = $false
        if (($action.bit -band $combinedSum) -ne 0)
        {
            $actionAllowed = $true
        }
        $repoObj | Add-Member -NotePropertyName "Acls$($action.name)Allowed" -NotePropertyValue $actionAllowed
    }
}


# Begin of main script

if (-not $ExcludePermissions.IsPresent)
{
    $gitSecNamespace = & "$PSScriptRoot\Helpers\Get-RepoSecurityNamespace.ps1" -OrgName $OrgName
    if ($null -eq $gitSecNamespace)
    {
        Write-Error "Git repos security namespace not found found for org $OrgName"
        exit 1
    }
}

if ($ProjectName -eq "")
{
    # Get repos from all projects
    $requestUrl = "https://dev.azure.com/$OrgName/_apis/projects?api-version=7.0"
    $projects = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" $requestUrl
    foreach ($project in $projects.Value)
    {
        GetReposOfProject -orgName $OrgName -projectName $project.Name -excludePermissions $ExcludePermissions -gitSecNamespace $gitSecNamespace
    }
}
else
{
    # Get only repos from specified project
    GetReposOfProject -orgName $OrgName -projectName $ProjectName -excludePermissions $ExcludePermissions -gitSecNamespace $gitSecNamespace
}
