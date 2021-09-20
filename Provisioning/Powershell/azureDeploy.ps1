#requires -Modules Az.Resources
Function ConvertIPtoInt64 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [String]
        $IpAddress
    ) 
    $octets = $IpAddress.split(".") 
    write-output ([int64]([int64]$octets[0] * 16777216 + [int64]$octets[1] * 65536 + [int64]$octets[2] * 256 + [int64]$octets[3]) )
}

Function ConvertInt64toIP {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [Int64]
        $Int
    ) 

    $FirstOctet = ([math]::truncate($Int / 16777216)).tostring()
    $SecondOctet = ([math]::truncate(($Int % 16777216) / 65536)).tostring()
    $thirdOctet = ([math]::truncate(($Int % 65536) / 256)).tostring()
    $fourthOctet = ([math]::truncate(($Int % 65536) / 256)).tostring()
    Write-output ($FirstOctet + "." + $SecondOctet + "." + $thirdOctet + "." + $fourthOctet )
}

Function InCidr {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $CIDR,
        [Parameter(Mandatory = $true)]
        [string]
        $ipAddress
    )

    $maskTable = @{
        0  = 4294967296
        1  = 2147483648
        2  = 1073741824
        3  = 536870912
        4  = 268435456
        5  = 134217728
        6  = 33554432
        7  = 33554432
        8  = 16777216
        9  = 8388608
        10 = 4194304
        11 = 2097152
        12 = 1048576
        13 = 524288
        14 = 262144
        15 = 131072
        16 = 65536
        17 = 32768
        18 = 16384
        19 = 8192
        20 = 4096
        21 = 2048
        22 = 1024
        23 = 512
        24 = 256
        25 = 128
        26 = 64
        27 = 32
        28 = 16
        29 = 8
        30 = 4
        31 = 2
        32 = 1
    }

    $range = $maskTable = $CIDR.Split('/')
    If($range -notin $maskTable){
        Write-Error "The CIDR, < $range > does not fall in the range of 0 to 32"
        exit
    }


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

        [Parameter()]
        [switch]$publicIp = [switch]$false

    )

    if(Get-AzVmResourceGroup - )
    Write-Verbose -Message "Creating VM Resource Group"

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
        try {
            New-AzVirtualNetwork @virtualNetworkParamSplat
        }
        Catch {
            Write-Error "Unable to create Virtual Network $vNetName. Error < $_.Exception >"
        }
        

    }

    Write-Verbose -Message "Setting up IP Configurations"
    $ipConfigParamSplat = @{
        Name = "Primary"
        PrivateIpAddressVersion = "IPv4"
        SubnetId = $subnetResourceId
        ErrorAction = "Stop"
    }
    
    New-AzNetworkInterfaceIpConfig @ipConfigParamSplat

    New-AzNetworkInterface -Name ($resoureName + "VNIC") -
}