[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $OrgName,

    [Parameter(Mandatory=$true)]
    [string]
    $ProjectName,

    [Parameter(Mandatory=$true)]
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

$IdentitiesCache = @{}


function CallApiWithToken($url, $method = "GET", $acl)
{
    $authString = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":" + $env:RemoveAzureGitRepoWritePermissions_PAT))

    $requestArgs = @{
        Method      = $method
        Uri         = $url
        Headers     = @{Authorization = $authString }
    }

    if ($null -ne $acl)
    {
        $requestBody = @{
            "count" = 1
            "value" = @( $acl )
        }
    
        $requestArgs.Body        = $requestBody | ConvertTo-Json -Depth 6
        $requestArgs.ContentType = "application/json"
    }

    Invoke-RestMethod @requestArgs
}

function GetGitRepoSecurityNamespace($orgName)
{
    $requestUrl = "https://dev.azure.com/$orgName/_apis/securitynamespaces?api-version=6.0"
    $allNamespacesResponse = CallApiWithToken $requestUrl
    $allNamespacesResponse.value | Where-Object { $_.name -eq "Git Repositories" }
}

function GetGitRepoId($orgName, $projectName, $repoName)
{
    $requestUrl = "https://dev.azure.com/$orgName/$projectName/_apis/git/repositories/$($repoName)?api-version=7.1-preview.1"
    $repoResponse = CallApiWithToken $requestUrl
    $repoResponse.id
}

function GetAndDisplayGitRepoAcls($orgName, $gitSecNamespace, $repoId)
{
    $acls = $null
    $acls = GetGitRepoAcls $OrgName $gitSecNamespace.namespaceId $repoId
    if ($null -eq $acls) 
    {
        Write-Host "No ACLs found for git repo $repoId"
    }
    else
    {
        DisplayGitRepoAcls $orgName $acls $gitSecNamespace.actions    
    }

    $acls
}

function GetGitRepoAcls($orgName, $securityNamespaceId, $repoId)
{
    $requestUrl = "https://dev.azure.com/$orgName/_apis/accesscontrollists/$($securityNamespaceId)?includeExtendedInfo=True&api-version=6.0"
    $allRepoAclsResponse = $null
    $allRepoAclsResponse = CallApiWithToken $requestUrl
    $allRepoAcls = $allRepoAclsResponse.value
    $allRepoAcls | Where-Object { $_.token.StartsWith("repoV2") -and $_.token.EndsWith($repoId) }
}

function DisplayGitRepoAcls($orgName, $acls, $gitSecActions)
{
    foreach ($acl in $acls)
    {
        Write-Host " - ACL"
        Write-Host "   Token: $($acl.token)"
        Write-Host "   InheritPermissions: $($acl.inheritPermissions)"
        foreach ($ace in $acl.acesDictionary.PSObject.Properties)
        {
            Write-Host "    - ACE"
            $identityName = GetIdentityName $orgName $ace.Value.descriptor
            Write-Host "      Descriptor: $identityName"
            $allowPerms = RenderPermissionsValue $ace.Value.extendedInfo.effectiveAllow $gitSecActions
            Write-Host "      Allow: $allowPerms"
            $denyPerms = RenderPermissionsValue $ace.Value.extendedInfo.effectiveDeny $gitSecActions
            Write-Host "      Deny:  $denyPerms"
        }
    }    
}

function GetIdentityName($orgName, $descriptor)
{
    $displayName = $IdentitiesCache[$descriptor]
    if ($null -eq $displayName)
    {
        $requestUrl =  "https://vssps.dev.azure.com/$orgName/_apis/identities?descriptors=$($descriptor)"
        $response = CallApiWithToken $requestUrl
        $displayName = $response[0].DisplayName

        $IdentitiesCache.Add($descriptor, $displayName)
    }
    $displayName
}

function RenderPermissionsValue($bits, $actions)
{
    if ($null -eq $bits)
    {
        $bits = 0
    }
    $binary = ToStringBinary $bits
    $perms = ExpandPermissions $bits $actions
    "$binary $perms"
}

function ToStringBinary($bits)
{
    [Convert]::ToString($bits, 2).PadLeft(16, '0')    
}

function ExpandPermissions($bits, $actions)
{
    $actions | Where-Object { $_.bit -band $bits } | ForEach-Object { $_.name }
}

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
    CallApiWithToken $requestUrl "POST" $acl
}


# Begin of main script

if ($null -eq $env:RemoveAzureGitRepoWritePermissions_PAT)
{
    throw "Please set the environment variable RemoveAzureGitRepoWritePermissions_PAT to a valid PAT token with Code: read and Security: manage permissions."
}

$gitSecNamespace = GetGitRepoSecurityNamespace $OrgName
if ($null -eq $gitSecNamespace) 
{
    Write-Host "Git repos security namespace not found in $OrgName"
    exit 0
}

$gitRepoId = GetGitRepoId $OrgName $ProjectName $RepoName


Write-Host "Removing write permissions for org: $OrgName, project: $ProjectName, repo: $RepoName"
Write-Host

Write-Host "Original permission values"
Write-Host "--------------------------"
$repoAcls = GetAndDisplayGitRepoAcls $OrgName $gitSecNamespace $gitRepoId
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
GetAndDisplayGitRepoAcls $OrgName $gitSecNamespace $gitRepoId | Out-Null
Write-Host