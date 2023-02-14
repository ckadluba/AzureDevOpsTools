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

function DisplayGitRepoAcls
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $orgName,

        [Parameter(Mandatory = $true)]
        $acls,

        [Parameter(Mandatory = $true)]
        $gitSecActions,

        [Parameter(Mandatory = $true)]
        $identitiesCache
    )

    foreach ($acl in $acls)
    {
        Write-Host " - ACL"
        Write-Host "   Token: $($acl.token)"
        Write-Host "   InheritPermissions: $($acl.inheritPermissions)"
        foreach ($ace in $acl.acesDictionary.PSObject.Properties)
        {
            Write-Host "    - ACE"
            $identityName = GetIdentityName -orgName $orgName -descriptor $ace.Value.descriptor -identitiesCache $identitiesCache
            Write-Host "      Descriptor: $identityName"
            $allowPerms = RenderPermissionsValue -bits $ace.Value.extendedInfo.effectiveAllow -actions $gitSecActions
            Write-Host "      Allow: $allowPerms"
            $denyPerms = RenderPermissionsValue -bits $ace.Value.extendedInfo.effectiveDeny -actions $gitSecActions
            Write-Host "      Deny:  $denyPerms"
        }
    }
}

function GetIdentityName
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $orgName,

        [Parameter(Mandatory = $true)]
        [string]
        $descriptor,

        [Parameter(Mandatory = $true)]
        $identitiesCache
    )

    $displayName = $identitiesCache[$descriptor]
    if ($null -eq $displayName)
    {
        $requestUrl =  "https://vssps.dev.azure.com/$orgName/_apis/identities?descriptors=$($descriptor)"
        $response = & "$PSScriptRoot\Call-ApiWithToken.ps1" -Url $requestUrl
        $displayName = $response[0].DisplayName

        $IdentitiesCache.Add($descriptor, $displayName)
    }
    $displayName
}

function RenderPermissionsValue
{
    param (
        [Parameter(Mandatory = $false)]
        $bits,

        [Parameter(Mandatory = $true)]
        $actions
    )

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
    DisplayGitRepoAcls -orgName $OrgName -acls $Acls -gitSecActions $GitSecNamespace.actions -identitiesCache $IdentitiesCache
}
