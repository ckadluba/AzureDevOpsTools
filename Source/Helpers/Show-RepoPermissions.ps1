[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $OrgName,

    [Parameter(Mandatory)]
    $GitSecNamespace,

    [Parameter(Mandatory)]
    $Acls,

    [Parameter()]
    $IdentitiesCache = @{}
)

function DisplayGitRepoAcls
{
    param (
        [Parameter(Mandatory)]
        [string]
        $orgName,

        [Parameter(Mandatory)]
        $acls,

        [Parameter(Mandatory)]
        $gitSecActions,

        [Parameter(Mandatory)]
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
        [Parameter(Mandatory)]
        [string]
        $orgName,

        [Parameter(Mandatory)]
        [string]
        $descriptor,

        [Parameter(Mandatory)]
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
        [Parameter()]
        $bits,

        [Parameter(Mandatory)]
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
