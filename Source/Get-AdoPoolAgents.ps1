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
    $WorkerNamePrefix
)


# Begin of main script

$requestUrl = "$ServerUrl/$OrgName/_apis/distributedtask/elasticpools?api-version=7.1-preview.1"
$queuesResponse = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl
if ($queuesResponse.Count -eq 0)
{
    Write-Error "No queues found."
    exit 0
}

$poolQueue = $queuesResponse.Value | Where-Object { $_.AzureId.EndsWith($WorkerNamePrefix) } | Select-Object -First 1
if ($null -eq $poolQueue)
{
    Write-Error "Matching queue not found."
    exit 0
}

# Get agents
$requestUrl = "$ServerUrl/$OrgName/_apis/distributedtask/pools/$($poolQueue.PoolId)/agents?api-version=7.0"
$agentsResponse = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl
if ($agentsResponse.Count -eq 0)
{
    Write-Error "No agents found."
    exit 0
}

$onlineAgents = $agentsResponse.Value | Where-Object { $_.Status -eq "online" }
foreach ($onlineAgent in $onlineAgents)
{
    [PSCustomObject] @{
        CreatedOn         = $onlineAgent.CreatedOn
        StatusChangedOn   = $onlineAgent.StatusChangedOn
        Id                = $onlineAgent.Id
        PoolId            = $poolQueue.PoolId
        Name              = $onlineAgent.Name
        Version           = $onlineAgent.Cersion
        OsDescription     = $onlineAgent.OsDescription
        Enabled           = $onlineAgent.Enabled
        Status            = $onlineAgent.Status
        ProvisioningState = $onlineAgent.ProvisioningState
    }
}
