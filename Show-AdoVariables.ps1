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

    [Parameter(Mandatory = $false)]
    [string]
    $ValueMatchExpression
)

function ShowMatchedVariables
{
    param (
        [Parameter(Mandatory = $true)]
        $vargroups
    )

    foreach ($vargroup in $vargroups)
    {
        foreach ($variable in $vargroup.variables.PSObject.Properties)
        {
            Write-Host "Group: $($vargroup.name), variable: $($variable.Name), value: $($variable.Value.value)"
        }
    }
}


# Begin of main script

Write-Host "Searching variables in org: $OrgName, project: $ProjectName"
$vargroups = & "$PSScriptRoot\Get-AdoVariableGroups.ps1" -OrgName $OrgName -ProjectName $ProjectName -VargroupNames $VargroupNames -Raw
if ($null -eq $vargroups)
{
    Write-Error "Specified variable groups not found in org: $OrgName, project $ProjectName!"
    exit 2
}
Write-Host ""

$matchedVargroups = & "$PSScriptRoot\Helpers\Get-AdoVariablesFromObjects.ps1" -Vargroups $vargroups -NameExpressions $VariableNameExpressions -ValueExpression $ValueMatchExpression
if ($matchedVargroups.Count -eq 0)
{
    Write-Host "No matching variables found"
}
else
{
    Write-Host "Matched variables"
    ShowMatchedVariables -vargroups $matchedVargroups
}
