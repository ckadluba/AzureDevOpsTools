[CmdletBinding()]
param (
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

$requestUrl = "https://dev.azure.com/$OrgName/$ProjectName/_apis/git/repositories/$($RepoName)?api-version=7.1-preview.1"
$repoResponse = & "$PSScriptRoot\Call-ApiWithToken.ps1" -Url $requestUrl
$repoResponse.id
