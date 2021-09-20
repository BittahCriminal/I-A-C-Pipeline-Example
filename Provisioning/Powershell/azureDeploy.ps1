#requires -Modules Az.Resources
Function New-AzureVirtualMachine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $resoureName,

        [Parameter(Mandatory=$true)]
        [string]

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
    
    $ipconfig = New-AzNetworkInterfaceIpConfig @ipConfigParamSplat

    $vNicParamSplat = @{
        Name = ($resoureName + "VNIC")
        ResourceGeoupName = $resou
        Location = $location
        IPconfiguration = $ipconfig
    }
    $vnic = New-AzNetworkInterface @vNicParamSplat
}