[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $OrgName,

    [Parameter(Mandatory)]
    [string]
    $ProjectName,

    [Parameter(Mandatory)]
    [string[]]
    $VargroupNames,

    [Parameter()]
    [string[]]
    $VariableNameExpressions,

    [Parameter(Mandatory)]
    [string]
    $ValueMatchExpression,

    [Parameter(Mandatory)]
    [string]
    $ValueReplaceExpression,

    [Parameter()]
    [switch]
    $Confirm
)

function CreateChanges
{
    param (
        [Parameter(Mandatory)]
        $fullVargroups,

        [Parameter(Mandatory)]
        $matchingVargroups,

        [Parameter(Mandatory)]
        [string]
        $matchExpression,

        [Parameter(Mandatory)]
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
            $matchingVariable = $matchingVargroup.variables.PSObject.Properties | Where-Object { $_.Name -eq $variable.Name }
            if ($null -eq $matchingVariable)
            {
                continue
            }

            # Execute regex replace
            $newValue = $variable.Value.value -replace $matchExpression, $replaceExpression
            if ($newValue -ne $variable.Value.value)
            {
                Write-Host "Group: $($vargroup.name), variable: $($variable.Name), current value: $($variable.Value.value), new value: $($newValue)"
                $variable.Value.value = $newValue
            }
        }
    }
}

function UpdateVariableGroups
{
    param (
        [Parameter(Mandatory)]
        [string]
        $orgName,

        [Parameter(Mandatory)]
        [string]
        $projectName,

        [Parameter(Mandatory)]
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

$matchingVargroups = & "$PSScriptRoot\Helpers\Get-AdoVariablesFromObjects.ps1" -Vargroups $vargroups -NameExpressions $VariableNameExpressions -ValueExpression $ValueMatchExpression
if ($matchingVargroups.Count -eq 0)
{
    Write-Host "No matching variables found"
    exit 0
}

$fullVargroups = & "$PSScriptRoot\Helpers\Get-AdoVariablesFromObjects.ps1" -Vargroups $vargroups

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
