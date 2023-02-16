[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    $Vargroups,

    [Parameter()]
    [string[]]
    $NameExpressions,

    [Parameter(Mandatory = $false)]
    [string]
    $ValueExpression
)

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


# Begin of main script

foreach ($vargroup in $Vargroups)
{
    $matchesFound = $false
    $matchedVariables = New-Object -TypeName PSObject
    foreach ($variable in $vargroup.variables.PSObject.Properties)
    {
        if (-not (IsNameMatching -name $variable.name -matchExpressions $NameExpressions))
        {
            continue
        }
        if ($variable.value.isSecret)
        {
            Write-Warning "Cannot read value of secret variable $($variable.Name) in group $($vargroup.name)"
            continue
        }
        if ($variable.value.isHidden)
        {
            Write-Warning "Cannot read value of hidden variable $($variable.Name) in group $($vargroup.name)"
            continue
        }

        # Execute regex match
        if (($ValueExpression -eq "") -or ($variable.Value.value -match $ValueExpression))
        {
            $matchedVariables | Add-Member -NotePropertyName $variable.name -NotePropertyValue $variable.Value
            $matchesFound = $true
        }

    }

    if ($matchesFound)
    {
        $matchedVargroup = New-Object -TypeName PSObject
        $matchedVargroup | Add-Member -NotePropertyName "id" -NotePropertyValue $vargroup.id
        $matchedVargroup | Add-Member -NotePropertyName "name" -NotePropertyValue $vargroup.name
        $matchedVargroup | Add-Member -NotePropertyName "variables" -NotePropertyValue $matchedVariables
        $matchedVargroup | Add-Member -NotePropertyName "variableGroupProjectReferences" -NotePropertyValue $vargroup.variableGroupProjectReferences
    
        $matchedVargroup
    }
}
