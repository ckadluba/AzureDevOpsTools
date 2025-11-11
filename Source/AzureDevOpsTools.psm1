function Get-AdoGitRepos
{
    param (
        [Parameter()]
        [string]
        $ServerUrl,

        [Parameter()]
        [string]
        $OrgName,

        [Parameter()]
        [string]
        $ProjectName = "",

        [Parameter()]
        [switch]
        $ExcludePermissions
    )

    $params = & "$PSScriptRoot\Helpers\Add-DefaultParams.ps1" $PSBoundParameters

    & "$PSScriptRoot\Get-AdoGitRepos.ps1" @params
}

function Get-AdoPoolJobs
{
    param (
        [Parameter()]
        [string]
        $ServerUrl,

        [Parameter()]
        [string]
        $OrgName,

        [Parameter(Mandatory)]
        [string]
        $PoolName
    )

    $params = & "$PSScriptRoot\Helpers\Add-DefaultParams.ps1" $PSBoundParameters

    & "$PSScriptRoot\Get-AdoPoolJobs.ps1" @params
}

function Get-AdoPoolAgents
{
    param (
        [Parameter()]
        [string]
        $ServerUrl,

        [Parameter()]
        [string]
        $OrgName,
    
        [Parameter(Mandatory)]
        [string]
        $WorkerNamePrefix
    )

    $params = & "$PSScriptRoot\Helpers\Add-DefaultParams.ps1" $PSBoundParameters

    & "$PSScriptRoot\Get-AdoPoolAgents.ps1" @params
}

function Get-AdoVariableGroups
{
    param (
        [Parameter()]
        [string]
        $ServerUrl,

        [Parameter()]
        [string]
        $OrgName,
    
        [Parameter()]
        [string]
        $ProjectName,
    
        [Parameter(Mandatory)]
        [string[]]
        $VargroupNames,
    
        [Parameter()]
        [switch]
        $Raw
    )

    $params = & "$PSScriptRoot\Helpers\Add-DefaultParams.ps1" $PSBoundParameters

    & "$PSScriptRoot\Get-AdoVariableGroups.ps1" @params
}

function Remove-AdoGitRepoWritePermissions
{
    param (
        [Parameter()]
        [string]
        $ServerUrl,

        [Parameter()]
        [string]
        $OrgName,
    
        [Parameter()]
        [string]
        $ProjectName,
    
        [Parameter(Mandatory)]
        [string]
        $RepoName,
    
        [Parameter()]
        [switch]
        $Confirm
    )
            
    $params = & "$PSScriptRoot\Helpers\Add-DefaultParams.ps1" $PSBoundParameters

    & "$PSScriptRoot\Remove-AdoGitRepoWritePermissions.ps1" @params
}

function Show-AdoVariables
{
    param (
        [Parameter()]
        [string]
        $ServerUrl,

        [Parameter()]
        [string]
        $OrgName,

        [Parameter()]
        [string]
        $ProjectName,

        [Parameter(Mandatory)]
        [string[]]
        $VargroupNames,

        [Parameter()]
        [string[]]
        $VariableNameExpressions,

        [Parameter()]
        [string]
        $ValueMatchExpression
    )
            
    $params = & "$PSScriptRoot\Helpers\Add-DefaultParams.ps1" $PSBoundParameters

    & "$PSScriptRoot\Show-AdoVariables.ps1" @params
}

function Update-AdoVariables
{
    param (
        [Parameter()]
        [string]
        $ServerUrl,

        [Parameter()]
        [string]
        $OrgName,
    
        [Parameter()]
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
            
    $params = & "$PSScriptRoot\Helpers\Add-DefaultParams.ps1" $PSBoundParameters

    & "$PSScriptRoot\Update-AdoVariables.ps1" @params
}

Export-ModuleMember -Function Get-AdoGitRepos
Export-ModuleMember -Function Get-AdoPoolJobs
Export-ModuleMember -Function Get-AdoPoolAgents
Export-ModuleMember -Function Get-AdoVariableGroups
Export-ModuleMember -Function Remove-AdoGitRepoWritePermissions
Export-ModuleMember -Function Show-AdoVariables
Export-ModuleMember -Function Update-AdoVariables
