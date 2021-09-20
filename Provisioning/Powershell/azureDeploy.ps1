#requires -Modules Az.Resources
function IsIpAddressInRange {
    param(
        [Parameter(Mandatory=$true)]
        [string] $ipAddress,
        [Parameter(Mandatory=$true)]
        [string] $fromAddress,
        [Parameter(Mandatory=$true)]
        [string] $toAddress
    )
    
        $ip = [system.net.ipaddress]::Parse($ipAddress).GetAddressBytes()
        [array]::Reverse($ip)
        $ip = [system.BitConverter]::ToUInt32($ip, 0)
    
        $from = [system.net.ipaddress]::Parse($fromAddress).GetAddressBytes()
        [array]::Reverse($from)
        $from = [system.BitConverter]::ToUInt32($from, 0)
    
        $to = [system.net.ipaddress]::Parse($toAddress).GetAddressBytes()
        [array]::Reverse($to)
        $to = [system.BitConverter]::ToUInt32($to, 0)
    
        $from -le $ip -and $ip -le $to
    }
Function New-AzureVirtualMachine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [TypeName]
        $resoureName,

        [Parameter(Mandatory = $true)]
        [ValidateScript(
            {
                $locations = (Get-AzLocation).location
                $_ -in $locations
            }
        )]
        [string]
        $location,

        [Parameter(Mandatory = $true)]
        [pscustomobject]$tags,
        
        [Parameter(ParameterSetName = "existingNetwork", Mandatory = $true)]
        [string]$subnetResourceId,
        
        [Parameter(ParameterSetName = "existingNetwork", Mandatory = $true)]
        [string]$vNetResourceId,

        [Parameter(ParameterSetName = "NewNetwork", Mandatory = $true)]
        [string]$subnetName,
        
        [Parameter(ParameterSetName = "NewNetwork", Mandatory = $true)]
        [string]$vNetName,

        [Parameter(ParameterSetName = "NewNetwork", Mandatory = $true)]
        [string]$addressPrefix,

        [Parameter(ParameterSetName = "NewNetwork", Mandatory = $true)]
        [string]$vNetResourceGroupName,

        [Parameter(Mandatory = $false)]
        [int]$numberOfDisks = 2,

        [Parameter()]
        [switch]$publicIp = [switch]$false

    )

    Write-Verbose -Message "Creating virtual Network if applicable"
    if ($vNetName) {
        Write-Verbose -Message "Creating Vnet resource group"
        $resourceGroupParamSplat = @{
            Name        = $vNetResourceId
            Location    = $location
            ErrorAction = "Stop"
        }
        try {
            New-AzResourceGroup @resourceGroupParamSplat
        }
        catch {
            Write-Error "Unable to create Resource group. Error < $_.Exception >"
        }

        write-verbose "Creating Subnet in the Vnet $vNetName"

        $subnetNetworkParamSplat = @{
            Name = $subnetName
            AddressPrefix = $addressPrefix
            ErrorAction       = "Stop"
        }
        $subnet = New-AzVirtualNetworkSubnetConfig @subnetNetworkParamSplat

        write-verbose "Creating a virtual network"
        $virtualNetworkParamSplat = @{
            Name              = $vNetName
            ResourceGroupName = $vNetResourceGroupName
            Location          = $location
            AddressPrefix     = $addressPrefix
            ErrorAction       = "Stop"
            Subnet = $subnet
        }
        New-AzVirtualNetwork @virtualNetworkParamSplat -sub

    }

    Write-Verbose -Message "Setting up IP Configurations"
    $ipConfigParamSplat = @{
        Name = "Primary"
        PrivateIpAddressVersion = "IPv4"
        SubnetId = $subnetResourceId

    }
    
    New-AzNetworkInterfaceIpConfig -Name "primary" -PrivateIpAddressVersion IPv4 -Primary -SubnetId $subnetResourceId
}