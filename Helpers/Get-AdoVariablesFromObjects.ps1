[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    $Vargroups,

    [Parameter()]
    [string[]]
    $NameExpressions,

    [Parameter()]
    [string]
    $ValueExpression
)

function IsNameMatching
{
    param (
        [Parameter(Mandatory)]
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

        if ($ValueExpression -eq "")
        {
            # No value match expression, take any variable that matches by name
            $matchedVariables | Add-Member -NotePropertyName $variable.name -NotePropertyValue $variable.Value
            $matchesFound = $true
        }
        else
        {
            if ($variable.value.isSecret -or $variable.value.isHidden)
            {
                Write-Warning "Cannot read value of secret or hidden variable $($variable.Name) in group $($vargroup.name)"
            }
            elseif ($variable.Value.value -match $ValueExpression)
            {
                $matchedVariables | Add-Member -NotePropertyName $variable.name -NotePropertyValue $variable.Value
                $matchesFound = $true
            }
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
