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
    [switch]
    $Raw
)

function GetFlatVargroupObject($vargroup)
{
    $vargroupFlatObj = New-Object -TypeName PSObject
    $vargroupFlatObj | Add-Member -NotePropertyName "_VarGroupId" -NotePropertyValue $vargroup.id
    $vargroupFlatObj | Add-Member -NotePropertyName "_VarGroupName" -NotePropertyValue $vargroup.name
    $vargroupFlatObj | Add-Member -NotePropertyName "_VarGroupCreatedBy" -NotePropertyValue "$($vargroup.createdBy.displayName) $($vargroup.createdBy.uniqueName)"
    $vargroupFlatObj | Add-Member -NotePropertyName "_VarGroupCreatedOn" -NotePropertyValue $vargroup.createdOn
    $vargroupFlatObj | Add-Member -NotePropertyName "_VarGroupModifiedBy" -NotePropertyValue "$($vargroup.modifiedBy.displayName) $($vargroup.modifiedBy.uniqueName)"
    $vargroupFlatObj | Add-Member -NotePropertyName "_VarGroupModifiedOn" -NotePropertyValue $vargroup.modifiedOn
    
    foreach ($variable in $vargroup.variables.PSObject.Properties)
    {
        $vargroupFlatObj | Add-Member -NotePropertyName $variable.Name -NotePropertyValue $variable.Value.value
    }

    $vargroupFlatObj
}    


# Begin of main script

foreach ($vargroupName in $VargroupNames)
{
    Write-Host "Getting variable group $vargroupName in org $orgName, project $projectName"

    $requestUrl = "https://dev.azure.com/$OrgName/$ProjectName/_apis/distributedtask/variablegroups?groupName=$($vargroupName)&api-version=7.1-preview.2" 
    $vargroupsResponse = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl
    
    if (($null -ne $vargroupsResponse) -and ($vargroupsResponse.Count -eq 1))
    {

        foreach ($vargroupRaw in $vargroupsResponse.value)
        {
            if ($Raw.IsPresent -eq $false)
            {
                GetFlatVargroupObject $vargroupRaw
            }
            else
            {
                $vargroupRaw
            }
        }
    }
}
