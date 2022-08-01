# RemoveAzureGitRepoWritePermissions

A PowerShell script to remove all read permissions from an Azure DevOps git repository.

Sometimes old repositories should be set read only "deactivated" in a way, that nobody can change the code anymore while keeping them
readable for reference purposes. In these cases disabling the repository is not a good option, because then it does not appear in the list of repositories in the UI anymore. This script can be used instead to remove all [write permissions](#write-permissions) from the repository. 

This script does the following modifications for all ACLs of a given repository

1. Disable permission inheritance
1. Removed explicit allow of [write permissions](#write-permissions) on all existing ACEs 
1. Set an explicit deny of [write permissions](#write-permissions) on all existing ACEs for the following actions: 
1. Display modfied ACLs and ACEs with old and new values

# Write Permissions

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

# Usage

1. In Azure DevOps UI create a PAT token in Azure DevOps that has the permissions __Code: read__, __Identity: read__ and __Security: manage__ in your project.  
1. Create the environment variable `RemoveAzureGitRepoWritePermissions_PAT` containing the PAT token.
1. Get the organisation, project name and repository name from the Azure DevOps UI.
1. Run the script to remove all [write permissions](#write-permissions) from the repository.
   ```powershell
   .\Remove-AzureGitRepoWritePermissions.ps1 -OrgName "myorganisation" -ProjectName "MyProject" -RepoName "MyRepo"
   ```
1. The script will first display the existing permissions set on the repository, then ask for user confirmation to continue or abort (unless called with parameter -Confirm), remove and update the permissions and read them again to display the updated permissions.

# Parameters

* OrgName (mandatory)
  The name of the Azure DevOps organization to use.
* ProjectName (mandatory)
  The name of the Azure DevOps project where the git repository is located.
* RepoName (mandatory)
  The name of the Azure DevOps git repository where the permissions should be changed.
* Confirm (optional)
  If this is set, the script won't ask the user for confirmation before changing the permissions.

# Prerequisites

* PowerShell 7
* Azure DevOps account with git repository
* Azure DevOps PAT token (__Code: read__, __Identity: read__ and __Security: manage__)

# Disclaimer

This script can remove permissions from your repositories. It can be very helpful and save you some time. But please be aware that, __you are using this script at your own risk__. I'm not responsible for any damage done by misuse or by any bugs that might exist in the script.