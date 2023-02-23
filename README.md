# SystemTeamTools PowerShell Module

A set of PowerShell scripts to accomplish different tasks in Azure DevOps.

## Getting Started 

You need one or two things before you can start. :)

### Prerequisites

* PowerShell 7
* Az PowerShell Module 4.7 or higher (https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.7.0)
* Azure DevOps PAT token (see individual prerequisites of each script below for necessary permissions)

### Setting the PAT token

1. In Azure DevOps UI create a PAT token in Azure DevOps that has the permissions mentioned below.  
1. Create the environment variable `AzureDevOpsTools_PAT` containing the PAT token.


## Get-TemplateParameters 

Gets the latests URL and SAS Token for the Base Templates (IaC_Templates). Use the currently checked-out branch when calling it from a git working copy of IaC_Templates or from a branch speficied.


## Test-PipelineYamlFile

Uses the Azure DevOps API to validate a single pipeline YAML file.


## Test-PipelineYamlTree

Uses the Azure DevOps API to validate local YAML changes based on an existing Azure Git repo and pipeline. 


## Get-PipelineTransition

Gets a list of pipelines which are not using the central build pools. 


## Set-PipelineTransitionCsv

Like Get-PipelineTransition but writes CSV result. 


## Get-AdoGitRepos

Gets a list of all git repositories within a specified organisation or within a specified project. The output includes information about the last commit and the combined types of permissions set on the repo.

### Usage

Get data of all git repos in organisation "myorganisation" and project "MyProject".

```powershell
.\Get-AdoGitRepos.ps1 -OrgName "myorganisation" -ProjectName "MyProject"
```

Get data of all git repos in all projects of organisation "myorganisation" and write ouput as CSV to file myorganisation-repos.csv.

```powershell
.\Get-AdoGitRepos.ps1 -OrgName "myorganisation" | ConvertTo-Csv > myorganisation-repos.csv
```

### Parameters

* OrgName (mandatory)  
  The name of the Azure DevOps organisation to use.
* ProjectName (optional)  
  The name of the Azure DevOps project where the git repositories are located. If this is omitted information about all repositories in all projects of the specified organisation is returned.
* ExcludePermissions (optional)  
  If this is set, the permissions of each repository are not included in the output. Choose this for faster execution.

### PAT Permissions

* Azure DevOps PAT token permission: __Code: read__


## Show-AdoGitRepoPermissions

Displays the permissions (access control lists) of a specified repository.

### Usage

Show permissions (access control lists) set on repository "MyRepo" in project "MyProject" in organisation "myorganisation".

```powershell
.\Show-AdoGitRepoPermissions.ps1 -OrgName "myorganisation" -ProjectName "MyProject" -RepoName "MyRepo"
```

### Parameters

* OrgName (mandatory)  
  The name of the Azure DevOps organisation to use.
* ProjectName (mandatory)  
  The name of the Azure DevOps project where the git repository is located.
* RepoName (mandatory)  
  The name of the Azure DevOps git repository where the permissions should be changed.

### PAT Permissions

* Azure DevOps PAT token permissions: __Code: read__ and __Identity: read__


## Remove-AdoGitRepoWritePermissions

Removes all write permissions from a repository.

Sometimes old repositories should be "deactivated" in a way, that nobody can change the code anymore while keeping it
readable for reference purposes. In these cases disabling the repository is not a good option, because then it does not appear in the list of repositories in the UI anymore. This script can be used to remove all [write permissions](#write-permissions) from the repository. 

This script does the following modifications for all ACLs of a given repository

1. Removed explicit allow of [write permissions](#write-permissions) on all existing ACEs 
2. Set an explicit deny of [write permissions](#write-permissions) on all existing ACEs for the following actions: 
3. Display modfied ACLs and ACEs with old and new values

The script will first display the existing permissions set on the repository, then ask for user confirmation to continue or abort (unless called with parameter -Confirm), remove and update the permissions and read them again to display the updated permissions.

### Write Permissions

The following write permissions are removed by the script for all users.

```
GenericContribute
ForcePush
CreateBranch
CreateTag
ManageNote
PolicyExempt
PullRequestContribute
PullRequestBypassPolicy
```

### Usage

Remove all write permissions from the ACL of the repository "MyRepo" in project "MyProject" in organisation "myorganisation".

```powershell
.\Remove-AdoGitRepoWritePermissions.ps1 -OrgName "myorganisation" -ProjectName "MyProject" -RepoName "MyRepo"
```

### Parameters

* OrgName (mandatory)  
  The name of the Azure DevOps organisation to use.
* ProjectName (mandatory)  
  The name of the Azure DevOps project where the git repository is located.
* RepoName (mandatory)  
  The name of the Azure DevOps git repository where the permissions should be changed.
* Confirm (optional)  
  If this is set, the script won't ask the user for confirmation before changing the permissions.

### PAT Permissions

* Azure DevOps PAT token permissions: __Code: read__, __Identity: read__ and __Security: manage__


## Get-AdoVariableGroups

Get contents of one or more variable groups.

### Usage

Get variable group "MyVariableGroup" in project "MyProject" in organisation "myorganisation".

```powershell
.\Get-AdoVariableGroups.ps1 -OrgName "myorganisation" -ProjectName "MyProject" -VargroupNames @( "MyVariableGroup" )
```

Get variable groups "MyGroup.Dev" and "MyGroup.Prod" in project "MyProject" in organisation "myorganisation" as CSV to file mygroup-vars.csv.

```powershell
.\Get-AdoVariableGroups.ps1 -OrgName "myorganisation" -ProjectName "MyProject" -VargroupNames @( "MyGroup.Dev", "MyGroup.Prod" ) | ConvertTo-Csv > mygroup-vars.csv
```

### Parameters

* OrgName (mandatory)  
  The name of the Azure DevOps organisation to use.
* ProjectName (mandatory)  
  The name of the Azure DevOps project where the variable group is located.
* VargroupName (mandatory)  
  The name of the variable group.
* Raw (optional)  
  If this is set, the script will return raw objects instead of flattened key-value collections. This is suitable to keep all information returned by the API for subsequent processing.

### PAT Permissions

* Azure DevOps PAT token permission: __Variable Groups: read__


## Show-AdoVariables

Searches and displays variables according to specified name and value search patterns from one or more variable groups.

### Usage

Find and display all variables containing the string "-legacy" in all variables with names starting with "ServerName" or `HostName" in the variable groups "MyVarGroup.Dev", "MyVarGroup.Test" and "MyVarGroup.Prod" in the project "MyProject" in organisation "myorganisation".

```powershell
.\Update-AdoVariables.ps1 -OrgName "myorganisation" -ProjectName "MyProject" -VargroupNames @( "MyVarGroup.Dev", "MyVarGroup.Test", "MyVarGroup.Prod" ) -VariableNameExpressions @( "ServerName.*", "HostName.*" ) -ValueMatchExpression "-legacy"

```

### Parameters

* OrgName (mandatory)  
  The name of the Azure DevOps organisation to use.
* ProjectName (mandatory)  
  The name of the Azure DevOps project where the variable group is located.
* VargroupNames (mandatory)  
  A list of names of variable groups to process.
* VariableNameExpressions (optional)  
  A list of regular expressions to select the names of the variables to process. It this is omitted, all variables in the specified groups will be processed.
* ValueMatchExpression (optional)  
  A regular expression to select variables by their value.

### PAT Permissions

* Azure DevOps PAT token permission: __Project and Team: read__ and __Variable Groups: read__


## Update-AdoVariables

Performs regex replacing in variable values of one or more variable groups.

### Usage

Replace the string "-legacy" with "-azure" in all variables with names starting with "ServerName" or `HostName" in the variable groups "MyVarGroup.Dev", "MyVarGroup.Test" and "MyVarGroup.Prod" in the project "MyProject" in organisation "myorganisation".

```powershell
.\Update-AdoVariables.ps1 -OrgName "myorganisation" -ProjectName "MyProject" -VargroupNames @( "MyVarGroup.Dev", "MyVarGroup.Test", "MyVarGroup.Prod" ) -VariableNameExpressions @( "ServerName.*", "HostName.*" ) -ValueMatchExpression "-legacy" -ValueReplaceExpression "-azure"
```

### Parameters

* OrgName (mandatory)  
  The name of the Azure DevOps organisation to use.
* ProjectName (mandatory)  
  The name of the Azure DevOps project where the variable group is located.
* VargroupNames (mandatory)  
  A list of names of variable groups to process.
* VariableNameExpressions (optional)  
  A list of regular expressions to select the names of the variables to process. It this is omitted, all variables in the specified groups will be processed.
* ValueMatchExpression (mandatory)  
  A regular expression to select a matching part of the variable values for replacement.
* ValueReplaceExpression (mandatory)  
  A regular expression to replace the matched part of the variable values.
* Confirm (optional)  
  If this is set, the script won't ask the user for confirmation before updating the variables.

### PAT Permissions

* Azure DevOps PAT token permission: __Project and Team: read__ and __Variable Groups: read, create, & manage__
