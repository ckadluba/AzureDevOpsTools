param (
    [hashtable]$GivenParameters
)

$finalParams = @{}

foreach ($k in $GivenParameters.Keys) {
    $finalParams[$k] = $GivenParameters[$k]
}

if (-not $finalParams.ContainsKey('ServerUrl') -and $env:AzureDevOpsTools_ServerUrl) {
    $finalParams['ServerUrl'] = $env:AzureDevOpsTools_ServerUrl
}
else {
    # Use public Azure DevOps Service if nothing else is specified
    $finalParams['ServerUrl'] = "https://dev.azure.com" 
}

if (-not $finalParams.ContainsKey('OrgName') -and $env:AzureDevOpsTools_OrgName) {
    $finalParams['OrgName'] = $env:AzureDevOpsTools_OrgName
}

if (-not $finalParams.ContainsKey('ProjectName') -and $env:AzureDevOpsTools_ProjectName) {
    $finalParams['ProjectName'] = $env:AzureDevOpsTools_ProjectName
}

return $finalParams