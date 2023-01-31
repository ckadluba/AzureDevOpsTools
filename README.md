# AzureGitRepoTools

A set of PowerShell scripts to accomplish different tasks on Azure DevOps git repositories.

## Getting Started 

You need one or two things before you can start. :)

### Prerequisites

* PowerShell 7
* Azure DevOps organisation with one or more git repositories
* Azure DevOps PAT token (see individual prerequisites of each script below for necessary permissions)

### Setting the PAT token

1. In Azure DevOps UI create a PAT token in Azure DevOps that has the permissions mentioned below.  
1. Create the environment variable `AzureGitRepoTools_PAT` containing the PAT token.

## Get-AzureGitRepos

Gets a list of all git repositories within a specified organisation or within a specified project. The output includes information about the last commit and the combined types of permissions set on the repo.

### Usage

Get data of all git repos in organisation "myorganisation" and project "MyProject".

```powershell
.\Get-AzureGitRepos.ps1 -OrgName "myorganisation" -ProjectName "MyProject"
```

Get data of all git repos in all projects of organisation "myorganisation" and write ouput as CSV to file myorganisation-repos.csv.

```powershell
.\Get-AzureGitRepos.ps1 -OrgName "myorganisation" | ConvertTo-Csv > myorganisation-repos.csv
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

## Show-AzureGitRepoPermissions

Displays the permissions (access control lists) of a specified repository.

### Usage

Show permissions (access control lists) set on repository "MyRepo" in project "MyProject" if organisation "myorganisation".

```powershell
.\Show-AzureGitRepoPermissions.ps1 -OrgName "myorganisation" -ProjectName "MyProject" -RepoName "MyRepo"
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

## RemoveAzureGitRepoWritePermissions

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

Remove all write permissions from the ACL of the repository "MyRepo" in project "MyProject" if organisation "myorganisation".

```powershell
.\Remove-AzureGitRepoWritePermissions.ps1 -OrgName "myorganisation" -ProjectName "MyProject" -RepoName "MyRepo"
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

### Disclaimer

This script can remove permissions from your repositories. It can be very helpful and save you some time. But please be aware that, __you are using this script at your own risk__. I'm not responsible for any damage done by misuse or by any bugs that might exist in the script.
