[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $OrgName,

    [Parameter(Mandatory)]
    [string]
    $PoolName
)

function GetPoolId
{
    param (
        [Parameter(Mandatory)]
        [string]
        $orgName,

        [Parameter(Mandatory)]
        [string]
        $poolName
    )

    Write-Debug "Get pool Id"

    $requestUrl = "https://dev.azure.com/$OrgName/_apis/projects?api-version=7.0"
    $projectsResponse = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl
    foreach ($project in $projectsResponse.Value)
    {
        $requestUrl = "https://dev.azure.com/$OrgName/$($project.Name)/_apis/distributedtask/queues?api-version=7.1-preview.1"
        $queuesResponse = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl
        foreach ($queue in $queuesResponse.Value)
        {
            if ($queue.Name -eq $poolName)
            {
                return $queue.Pool.Id
            }
        }
    }
}

function ReturnJobInfo
{
    param (
        [Parameter(Mandatory)]
        [string]
        $id,

        [Parameter(Mandatory)]
        [string]
        $type,

        [Parameter(Mandatory)]
        [string]
        $definitionName,

        [Parameter(Mandatory)]
        [string]
        $state,

        [Parameter()]
        [string]
        $queueName,

        [Parameter()]
        [string]
        $workerName,

        [Parameter(Mandatory)]
        [string]
        $queuedTime
    )

    [PSCustomObject] @{
        Id              = $id
        Type            = $type
        BuildDefinition = $definitionName
        State           = $state
        QueueName       = $queueName
        WorkerName      = $workerName
        QueuedTime      = $queuedTime
    }
}


# Begin of main script

# This is simple way to gather running jobs but it is using undocumented APIs

$poolId = GetPoolId -orgName $OrgName -poolName $PoolName
if ($null -eq $poolId)
{
    Write-Error "Pool $PoolName not found in organisation $OrgName"
    exit 1
}

$requestUrl = "https://$OrgName.visualstudio.com/_apis/distributedtask/pools/$poolId/jobrequests"
$jobsResponse = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl
foreach ($job in $jobsResponse.Value)
{
    $buildName = "$($job.Definition.Name) / $($job.Owner.Name)"
    if ($null -eq $job.ReservedAgent)
    {
        Write-Debug "PENDING Job id: $($job.RequestId), name: $buildName, agent: $($job.ReservedAgent.Name), queued: $($job.queueTime)"
        ReturnJobInfo -id $job.RequestId -type $job.PlanType -definitionName $buildName -state "pending" -queueName $PoolName -workerName "" -queuedTime $job.queueTime

    }
    elseif ($null -eq $job.Result)
    {
        Write-Debug "RUNNING Job id: $($job.RequestId), name: $buildName, agent: $($job.ReservedAgent.Name), queued: $($job.queueTime)"
        ReturnJobInfo -id $job.RequestId -type $job.PlanType -definitionName $buildName -state "inProgress" -queueName $PoolName -workerName $job.ReservedAgent.Name -queuedTime $job.queueTime
    }
}
