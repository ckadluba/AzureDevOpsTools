[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $OrgName = $null,

    [Parameter(Mandatory = $false)]
    [string]
    $ProjectName = "",

    [Parameter(Mandatory = $false)]
    [switch]
    $ExcludePermissions
)

function GetReposOfProject($orgName, $projectName, $excludePermissions, $gitSecNamespace)
{
    Write-Host "Checking repos for org: $orgName, project: $projectName"

    $requestUrl = "https://dev.azure.com/$orgName/$projectName/_apis/git/repositories?includeLinks=true&includeAllUrls=true&includeHidden=true&api-version=7.0"
    $repos = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl
    
    foreach ($repo in $repos.value)
    {
        Write-Host "Checking repo $($repo.name)"

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
            Write-Host "Getting last commit"
            AddLastCommitInfo $orgName $projectName $gitRepoId $repoObj

            if (-not $excludePermissions.IsPresent)
            {
                Write-Host "Getting permissions"
                AddPermissionsInfo $orgName $gitSecNamespace $gitRepoId $repoObj
            }
        }

        # Add project info
        $repoObj | Add-Member -NotePropertyName "ProjectName" -NotePropertyValue $repo.project.name
        $repoObj | Add-Member -NotePropertyName "ProjectUrl" -NotePropertyValue $repo.project.url
        $repoObj | Add-Member -NotePropertyName "ProjectVisibility" -NotePropertyValue $repo.project.visibility

        $repoObj
    }    
}

function AddLastCommitInfo($orgName, $projectName, $gitRepoId, $repoObj)
{
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

function AddPermissionsInfo($orgName, $gitSecNamespace, $gitRepoId, $repoObj)
{
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

    AddAclPermissionProperties $gitSecNamespace.actions $combinedAllowDenySum
}

function AddAclPermissionProperties($actions, $combinedSum)
{
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
    if ($null -eq $gitSecNamespace) {
        throw "Git repos security namespace not found found for org $OrgName"
    }
}

if ($ProjectName -eq "")
{
    # Get repos from all projects
    $requestUrl = "https://dev.azure.com/$OrgName/_apis/projects?api-version=7.0"
    $projects = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" $requestUrl
    foreach ($project in $projects.Value) {
        GetReposOfProject $OrgName $project.Name $ExcludePermissions $gitSecNamespace
    }
}
else
{
    # Get only repos from specified project
    GetReposOfProject $OrgName $ProjectName $ExcludePermissions $gitSecNamespace
}
