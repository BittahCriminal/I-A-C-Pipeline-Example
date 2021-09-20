#requires -Modules Az.Resources

Function New-AzureVirtualMachine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [TypeName]
        $resoureName,

        [Parameter(Mandatory=$true)]
        [ValidateScript(
            {
                $locations = (Get-AzLocation).location
                $_ -in $locations
            }
        )]
        [string]
        $location,

        [Parameter(Mandatory=$true)]
        [pscustomobject]$tags,

        [Parameter(Mandatory=$true)]
        [pscustomobject]$properties,

        [Parameter(Mandatory=$false)]
        [int]$numberOfDisks = 0,

        [Parameter()]
        [switch]$publicIp = [switch]$false

    )
    New-AzNetworkInterface -
    New-AzVMConfig 
}