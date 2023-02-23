[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [UInt16]
    $Bits
)

[Convert]::ToString($Bits, 2).PadLeft(16, '0')
