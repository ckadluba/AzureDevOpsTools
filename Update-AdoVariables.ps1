[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $OrgName,

    [Parameter(Mandatory = $true)]
    [string]
    $ProjectName,

    [Parameter(Mandatory = $true)]
    [string[]]
    $VargroupNames,

    [Parameter(Mandatory = $false)]
    [string[]]
    $VariableNameExpressions,

    [Parameter(Mandatory = $true)]
    [string]
    $ValueMatchExpression,

    [Parameter(Mandatory = $true)]
    [string]
    $ValueReplaceExpression,

    [Parameter(Mandatory = $false)]
    [switch]
    $Confirm
)

function CreateChanges
{
    param (
        [Parameter(Mandatory = $true)]
        $fullVargroups,

        [Parameter(Mandatory = $true)]
        $matchingVargroups,

        [Parameter(Mandatory = $true)]
        [string]
        $matchExpression,

        [Parameter(Mandatory = $true)]
        [string]
        $replaceExpression
    )

    foreach ($vargroup in $fullVargroups)
    {
        $matchingVargroup = $matchingVargroups | Where-Object -Property name -eq $vargroup.name
        if ($null -eq $matchingVargroup)
        {
            continue
        }

        foreach ($variable in $vargroup.variables.PSObject.Properties)
        {
            $matchingVariable = $matchingVargroup.variables | Where-Object -Property Name -eq $variable.Name
            if ($null -eq $matchingVariable)
            {
                continue
            }

            # Execute regex replace
            $newValue = $variable.Value.value -replace $matchExpression, $replaceExpression
            if ($newValue -ne $variable.Value.value)
            {
                Write-Host "Group: $($oldVargroup.name), variable: $($variable.Name), current value: $($variable.Value.value), new value: $($newValue)"
                $variable.Value.value = $newValue
            }
        }
    }
}

function UpdateVariableGroups
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $orgName,

        [Parameter(Mandatory = $true)]
        [string]
        $projectName,

        [Parameter(Mandatory = $true)]
        $newVargroups
    )

    foreach ($vargroup in $newVargroups)
    {
        $requestUrl = "https://dev.azure.com/$orgName/$projectName/_apis/distributedtask/variablegroups/$($vargroup.Id)?api-version=7.1-preview.2"
        & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl -Method "PUT" -Body $vargroup | Out-Null
    }
}


# Begin of main script

Write-Host "Updating variables in org: $OrgName, project: $ProjectName"
$vargroups = & "$PSScriptRoot\Get-AdoVariableGroups.ps1" -OrgName $OrgName -ProjectName $ProjectName -VargroupNames $VargroupNames -Raw
if ($null -eq $vargroups)
{
    Write-Error "Specified variable groups not found in org: $OrgName, project $ProjectName!"
    exit 2
}
Write-Host ""

$matchingVargroups = & "$PSScriptRoot\Helpers\Select-AdoVariables.ps1" -Vargroups $vargroups -NameExpressions $VariableNameExpressions -ValueExpression $ValueMatchExpression
if ($matchingVargroups.Count -eq 0)
{
    Write-Host "No matching variables found"
    exit 0
}

$fullVargroups = & "$PSScriptRoot\Helpers\Select-AdoVariables.ps1" -Vargroups $vargroups

Write-Host "List of changes"
CreateChanges -fullVargroups $fullVargroups -matchingVargroups $matchingVargroups -matchExpression $ValueMatchExpression -replaceExpression $ValueReplaceExpression
Write-Host ""

if (-not $Confirm.IsPresent)
{
    $confirmation = Read-Host "Do you want to continue?`n[Y] Yes  [N] No  (default is ""N"")"
    if ($confirmation -ne "y")
    {
        exit 0
    }
    Write-Host ""
}

Write-Host "Updating variables"
UpdateVariableGroups -orgName $OrgName -projectName $ProjectName -newVargroups $fullVargroups
