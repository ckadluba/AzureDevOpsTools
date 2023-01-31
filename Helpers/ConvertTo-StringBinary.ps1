[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [UInt16]
    $Bits
)

[Convert]::ToString($Bits, 2).PadLeft(16, '0')
