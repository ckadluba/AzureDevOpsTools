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

function GetProjectIdByName
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $orgName,

        [Parameter(Mandatory = $true)]
        [string]
        $projectName
    )

    $projects = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url "https://dev.azure.com/$orgName/_apis/projects?api-version=7.0"
    $project = $projects.value | Where-Object { $_.name -eq $projectName }
    $project.id
}

function CreateChanges
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $projectName,

        [Parameter(Mandatory = $true)]
        [string]
        $projectId,

        [Parameter(Mandatory = $true)]
        $oldVargroups,

        [Parameter()]
        [string[]]
        $nameExpressions,

        [Parameter(Mandatory = $true)]
        [string]
        $matchExpression,

        [Parameter(Mandatory = $true)]
        [string]
        $replaceExpression
    )

    $changeResult = @{
        "changesFound" = $false
        "newVargroups" = New-Object -TypeName Collections.Generic.List[PSObject]
    }
    foreach ($oldVargroup in $oldVargroups)
    {
        $newVargroup = New-Object -TypeName PSObject
        $newVargroup | Add-Member -NotePropertyName "id" -NotePropertyValue $oldVargroup.id
        $newVargroup | Add-Member -NotePropertyName "name" -NotePropertyValue $oldVargroup.name

        $newVariables = New-Object -TypeName PSObject
        foreach ($variable in $oldVargroup.variables.PSObject.Properties)
        {
            # By default keep existing value
            $newValue = $variable.Value.value

            if (-not (IsNameMatching -name $variable.name -matchExpressions $nameExpressions))
            {
                continue
            }
            if ($variable.value.isSecret)
            {
                Write-Warning "Cannot change value of secret variable $($variable.Name) in group $($oldVargroup.name)"
                continue
            }
            if ($variable.value.isHidden)
            {
                Write-Warning "Cannot change value of hidden variable $($variable.Name) in group $($oldVargroup.name)"
                continue
            }

            # Execute regex replace
            $newValue = $variable.Value.value -replace $matchExpression, $replaceExpression
            if ($newValue -ne $variable.Value.value)
            {
                Write-Host "Group: $($oldVargroup.name), variable: $($variable.Name), current value: $($variable.Value.value), new value: $($newValue)"
                $changeResult.changesFound = $true
            }

            $newVariables | Add-Member -NotePropertyName $variable.name -NotePropertyValue $newValue
        }
        $newVargroup | Add-Member -NotePropertyName "variables" -NotePropertyValue $newVariables

        $newVargroupProjectReference = New-Object -TypeName PSObject
        $newVargroupProjectReference | Add-Member -NotePropertyName "name" -NotePropertyValue $oldVargroup.name
        $newVargroupProjectReference | Add-Member -NotePropertyName "description" -NotePropertyValue $oldVargroup.description

        $newProjectReference = New-Object -TypeName PSObject
        $newProjectReference | Add-Member -NotePropertyName "name" -NotePropertyValue $projectName
        $newProjectReference | Add-Member -NotePropertyName "id" -NotePropertyValue $projectId
        $newVargroupProjectReference | Add-Member -NotePropertyName "projectReference" -NotePropertyValue $newProjectReference
        $newVargroup | Add-Member -NotePropertyName "variableGroupProjectReferences" -NotePropertyValue @( $newVargroupProjectReference )

        $changeResult.newVargroups.Add($newVargroup) | Out-Null
    }

    $changeResult
}

function IsNameMatching
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $name,

        [Parameter()]
        [string[]]
        $matchExpressions
    )

    if (($null -eq $matchExpressions) -or ($matchExpressions.Count -eq 0))
    {
        return $true
    }

    foreach ($expression in $matchExpressions)
    {
        if ($name -match $expression)
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

$projectId = GetProjectIdByName -orgName $OrgName -projectName $ProjectName
if ($null -eq $projectId)
{
    Write-Error "Project $ProjectName in org $OrgName not found!"
    exit 1
}

Write-Host "Updating variables in org: $OrgName, project: $ProjectName"
$oldVargroups = & "$PSScriptRoot\Get-AdoVariableGroups.ps1" -OrgName $OrgName -ProjectName $ProjectName -VargroupNames $VargroupNames -Raw
if ($null -eq $oldVargroups)
{
    Write-Error "Specified variable groups not found in org: $OrgName, project $ProjectName!"
    exit 2
}
Write-Host ""

Write-Host "Creating list of changes"
$changes = CreateChanges -projectName $ProjectName -projectId $projectId -oldVargroups $oldVargroups -nameExpressions $VariableNameExpressions -matchExpression $ValueMatchExpression -replaceExpression $ValueReplaceExpression
if (-not $changes.changesFound)
{
    Write-Host "No changes to be made"
    exit 3
}
Write-Host ""

if (-not $Confirm.IsPresent)
{
    $confirmation = Read-Host "Do you want to continue?`n[Y] Yes  [N] No  (default is ""N"")"
    if ($confirmation -ne "y")
    {
        exit 0
    }
}
Write-Host ""

Write-Host "Updating variables"
UpdateVariableGroups -orgName $OrgName -projectName $ProjectName -newVargroups $changes.newVargroups
