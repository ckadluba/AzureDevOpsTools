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
    $RepoName
)

$requestUrl = "$ServerUrl/$OrgName/$ProjectName/_apis/git/repositories/$($RepoName)?api-version=7.1-preview.1"
$repoResponse = & "$PSScriptRoot\Call-ApiWithToken.ps1" -Url $requestUrl
$repoResponse.id
