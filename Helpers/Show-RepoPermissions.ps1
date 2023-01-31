[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $OrgName,

    [Parameter(Mandatory = $true)]
    $GitSecNamespace,

    [Parameter(Mandatory = $true)]
    $Acls,

    [Parameter(Mandatory = $false)]
    $IdentitiesCache = @{}
)

function DisplayGitRepoAcls($orgName, $acls, $gitSecActions)
{
    foreach ($acl in $acls)
    {
        Write-Host " - ACL"
        Write-Host "   Token: $($acl.token)"
        Write-Host "   InheritPermissions: $($acl.inheritPermissions)"
        foreach ($ace in $acl.acesDictionary.PSObject.Properties)
        {
            Write-Host "    - ACE"
            $identityName = GetIdentityName $orgName $ace.Value.descriptor
            Write-Host "      Descriptor: $identityName"
            $allowPerms = RenderPermissionsValue $ace.Value.extendedInfo.effectiveAllow $gitSecActions
            Write-Host "      Allow: $allowPerms"
            $denyPerms = RenderPermissionsValue $ace.Value.extendedInfo.effectiveDeny $gitSecActions
            Write-Host "      Deny:  $denyPerms"
        }
    }    
}

function GetIdentityName($orgName, $descriptor)
{
    $displayName = $IdentitiesCache[$descriptor]
    if ($null -eq $displayName)
    {
        $requestUrl =  "https://vssps.dev.azure.com/$orgName/_apis/identities?descriptors=$($descriptor)"
        $response = & "$PSScriptRoot\Call-ApiWithToken.ps1" -Url $requestUrl
        $displayName = $response[0].DisplayName

        $IdentitiesCache.Add($descriptor, $displayName)
    }
    $displayName
}

function RenderPermissionsValue($bits, $actions)
{
    if ($null -eq $bits)
    {
        $bits = 0
    }
    $binary = & "$PSScriptRoot\ConvertTo-StringBinary.ps1" -Bits $bits
    $perms = ExpandPermissions $bits $actions
    "$binary $perms"
}

function ExpandPermissions($bits, $actions)
{
    $actions | Where-Object { $_.bit -band $bits } | ForEach-Object { $_.name }
}


# Begin of main script

if ($null -ne $Acls)
{
    DisplayGitRepoAcls $OrgName $Acls $GitSecNamespace.actions    
}
