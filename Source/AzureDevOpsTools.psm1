function Get-AdoGitRepos
{
    param (
        [Parameter(Mandatory)]
        [string]
        $OrgName,

        [Parameter()]
        [string]
        $ProjectName = "",

        [Parameter()]
        [switch]
        $ExcludePermissions
    )

    & "$PSScriptRoot\Get-AdoGitRepos.ps1" @PSBoundParameters
}

function Get-AdoPoolJobs
{
    param (
        [Parameter(Mandatory)]
        [string]
        $OrgName,

        [Parameter(Mandatory)]
        [string]
        $PoolName
    )

    & "$PSScriptRoot\Get-AdoPoolJobs.ps1" @PSBoundParameters
}

function Get-AdoPoolAgents
{
    param (
        [Parameter(Mandatory)]
        [string]
        $OrgName,
    
        [Parameter(Mandatory)]
        [string]
        $WorkerNamePrefix
    )

    & "$PSScriptRoot\Get-AdoPoolAgents.ps1" @PSBoundParameters
}

function Get-AdoVariableGroups
{
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
        [switch]
        $Raw
    )
    
    & "$PSScriptRoot\Get-AdoVariableGroups.ps1" @PSBoundParameters
}

function Remove-AdoGitRepoWritePermissions
{
    param (
        [Parameter(Mandatory)]
        [string]
        $OrgName,
    
        [Parameter(Mandatory)]
        [string]
        $ProjectName,
    
        [Parameter(Mandatory)]
        [string]
        $RepoName,
    
        [Parameter()]
        [switch]
        $Confirm
    )
            
    & "$PSScriptRoot\Remove-AdoGitRepoWritePermissions.ps1" @PSBoundParameters
}

function Update-AdoVariables
{
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
            
    & "$PSScriptRoot\Update-AdoVariables.ps1" @PSBoundParameters
}

Export-ModuleMember -Function Get-AdoGitRepos
Export-ModuleMember -Function Get-AdoPoolJobs
Export-ModuleMember -Function Get-AdoPoolAgents
Export-ModuleMember -Function Get-AdoVariableGroups
Export-ModuleMember -Function Remove-AdoGitRepoWritePermissions
Export-ModuleMember -Function Update-AdoVariables
