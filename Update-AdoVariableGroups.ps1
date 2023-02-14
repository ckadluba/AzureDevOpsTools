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
        $OldVargroups,

        [Parameter()]
        [string[]]
        $NameExpressions,

        [Parameter(Mandatory = $true)]
        [string]
        $MatchExpression,
    
        [Parameter(Mandatory = $true)]
        [string]
        $ReplaceExpression    
    )

    foreach ($oldVargroup in $OldVargroups)
    {
        $newVargroup = New-Object -TypeName PSObject
        $newVargroup | Add-Member -NotePropertyName "id" -NotePropertyValue $oldVargroup.id
        $newVargroup | Add-Member -NotePropertyName "name" -NotePropertyValue $oldVargroup.name
    
        $newVariables = New-Object -TypeName PSObject
        foreach ($variable in $oldVargroup.variables.PSObject.Properties)
        {
            if (IsNameMatching -Name $variable.name -MatchExpressions $NameExpressions)
            {
                $newValue = $variable.Value.value -replace $MatchExpression, $ReplaceExpression
                Write-Host "Variable group: $($oldVargroup.name), variable: $($variable.Name), old value: $($variable.Value.value) -> new value: $($newValue)"
            }
            else
            {
                $newValue = $variable.Value.value
            }
    
            $newVariables | Add-Member -NotePropertyName $variable.name -NotePropertyValue $newValue
        }
        $newVargroup | Add-Member -NotePropertyName "variables" -NotePropertyValue $newVariables
    
        $newVargroupProjectReference = New-Object -TypeName PSObject
        $newVargroupProjectReference | Add-Member -NotePropertyName "name" -NotePropertyValue $oldVargroup.name
        $newVargroupProjectReference | Add-Member -NotePropertyName "description" -NotePropertyValue $oldVargroup.description
        $newProjectReference = New-Object -TypeName PSObject
        $newProjectReference | Add-Member -NotePropertyName "name" -NotePropertyValue $ProjectName
        $newProjectReference | Add-Member -NotePropertyName "id" -NotePropertyValue "4d852e83-30b8-4418-b3d0-725b52aa2fa3"
        $newVargroupProjectReference | Add-Member -NotePropertyName "projectReference" -NotePropertyValue $newProjectReference
        $newVargroup | Add-Member -NotePropertyName "variableGroupProjectReferences" -NotePropertyValue @( $newVargroupProjectReference )
    
        $newVargroup
    }
}

function IsNameMatching
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [string[]]
        $MatchExpressions
    )

    if (($null -eq $MatchExpressions) -or ($MatchExpressions.Count -eq 0))
    {
        return $true
    }

    foreach ($expression in $MatchExpressions)
    {
        if ($Name -match $expression)
        {
            return $true
        }
    }

    return $false
}

function UpdateVariableGroups
{
    param (
        [Parameter(Mandatory = $true)]
        $NewVargroups
    )

    foreach ($vargroup in $NewVargroups)
    {
        $requestUrl = "https://dev.azure.com/$OrgName/$ProjectName/_apis/distributedtask/variablegroups/$($vargroup.Id)?api-version=7.1-preview.2"
        & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl -Method "PUT" -Body $vargroup | Out-Null        
    }
}


# Begin of main script

Write-Host "Updating variables in org: $OrgName, project: $ProjectName"
$oldVargroups = & "$PSScriptRoot\Get-AdoVariableGroups.ps1" -OrgName $OrgName -ProjectName $ProjectName -VargroupNames $VargroupNames -Raw
Write-Host ""

Write-Host "Prepared the following changes"
$newVargroups = CreateChanges -OldVargroups $oldVargroups -NameExpressions $VariableNameExpressions -MatchExpression $ValueMatchExpression -ReplaceExpression $ValueReplaceExpression
Write-Host ""

if ($Confirm.IsPresent -eq $false)
{
    $confirmation = Read-Host "Do you want to continue?`n[Y] Yes  [N] No  (default is ""N"")"
    if ($confirmation -ne "y")
    {
        exit 0
    }
}
Write-Host ""

Write-Host "Updating variables"
UpdateVariableGroups -NewVargroups $newVargroups
