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
    $RepoName
)

$requestUrl = "https://dev.azure.com/$OrgName/$ProjectName/_apis/git/repositories/$($RepoName)?api-version=7.1-preview.1"
$repoResponse = & "$PSScriptRoot\Call-ApiWithToken.ps1" $requestUrl
$repoResponse.id
