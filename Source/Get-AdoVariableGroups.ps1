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
    $ProjectName,

    [Parameter(Mandatory)]
    [string[]]
    $VargroupNames,

    [Parameter()]
    [switch]
    $Raw
)

function GetFlatVargroupObject
{
    param (
        [Parameter(Mandatory)]
        $vargroup
    )

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

function GetProjectIdByName
{
    param (
        [Parameter(Mandatory)]
        [string]
        $serverUrl,

        [Parameter(Mandatory)]
        [string]
        $orgName,

        [Parameter(Mandatory)]
        [string]
        $projectName
    )

    $projects = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url "$serverUrl/$orgName/_apis/projects?api-version=7.0"
    $project = $projects.value | Where-Object { $_.name -eq $projectName }
    $project.id
}


# Begin of main script

if ($Raw.IsPresent)
{
    $projectId = GetProjectIdByName -serverUrl $ServerUrl -orgName $OrgName -projectName $ProjectName
    if ($null -eq $projectId)
    {
        Write-Error "Project $ProjectName in org $OrgName not found!"
        exit 1
    }    
}

foreach ($vargroupName in $VargroupNames)
{
    Write-Debug "Getting variable group $vargroupName in org $orgName, project $projectName"

    $requestUrl = "$ServerUrl/$OrgName/$ProjectName/_apis/distributedtask/variablegroups?groupName=$($vargroupName)&api-version=7.1-preview.2"
    $vargroupsResponse = & "$PSScriptRoot\Helpers\Call-ApiWithToken.ps1" -Url $requestUrl

    if (($null -ne $vargroupsResponse) -and ($vargroupsResponse.Count -eq 1))
    {

        foreach ($vargroupRaw in $vargroupsResponse.value)
        {
            if (-not $Raw.IsPresent)
            {
                GetFlatVargroupObject -vargroup $vargroupRaw
            }
            else
            {
                # Project reference is used by Update-AdoVariables.ps1
                $matchedVargroupProjectReference = New-Object -TypeName PSObject
                $matchedVargroupProjectReference | Add-Member -NotePropertyName "name" -NotePropertyValue $vargroupRaw.name
                $matchedVargroupProjectReference | Add-Member -NotePropertyName "description" -NotePropertyValue $vargroupRaw.description
                $matchedProjectReference = New-Object -TypeName PSObject
                $matchedProjectReference | Add-Member -NotePropertyName "name" -NotePropertyValue $ProjectName
                $matchedProjectReference | Add-Member -NotePropertyName "id" -NotePropertyValue $projectId        
                $matchedVargroupProjectReference | Add-Member -NotePropertyName "projectReference" -NotePropertyValue $matchedProjectReference
                $vargroupRaw.variableGroupProjectReferences = @( $matchedVargroupProjectReference )
        
                $vargroupRaw
            }
        }
    }
}
