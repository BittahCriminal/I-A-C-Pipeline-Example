#requires -Modules Az.Resources
Function New-AzureVirtualMachine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $resoureName,

        [Parameter(Mandatory=$true)]
        [string]$resourceGroupName,

        [Parameter(Mandatory = $true)]
        [ValidateScript(
            {
                $locations = (Get-AzLocation).location
                $_ -in $locations
            }
        )]
        [string]
        $location,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Big','Medium','Small')]
        [string]$vmSize,

        [Parameter(Mandatory=$true)]
        [pscredential]$localCred,

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

    $vmSizeTable = @{
        Big = "Standard_D4_v2"
        Medium = "Standard_D2_v2"
        Small = "Standard_D1_v2"
    }
    if(!(Get-AzResourceGroup -Name $resourceGroupName)){
        New-AzResourceGroup -Name $resourceGroupName -Location $location -Tag $tags -force
    }

    Write-Verbose -Message "Creating virtual Network if applicable"
    if ($vNetName) {
        Write-Verbose -Message "Creating Vnet resource group"
        $resourceGroupParamSplat = @{
            Name        = $vNetResourceGroupName
            Location    = $location
            ErrorAction = "Stop"
            force = [switch]$true
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
            Tag = $tags
            force = [switch]$true
        }
        try {
            $vNet = New-AzVirtualNetwork @virtualNetworkParamSplat 
        }
        Catch {
            Write-Error "Unable to create Virtual Network $vNetName. Error < $_.Exception >"
        }
        

    }

    Write-Verbose -Message "Setting up IP Configurations"
    $ipConfigParamSplat = @{
        Name = "Primary"
        PrivateIpAddressVersion = "IPv4"
        ErrorAction = "Stop"
    }
    if($subnetResourceId){
        $ipConfigParamSplat.Add("SubnetId", $subnetResourceId)
    }
    else {
        $ipConfigParamSplat.Add("SubnetId", $vNet.Subnets.id)
    }
    
    $ipconfig = New-AzNetworkInterfaceIpConfig @ipConfigParamSplat 

    Write-verbose -Message "Setting up virtual network interface"
    $vNicParamSplat = @{
        Name = ($resoureName + "VNIC")
        ResourceGroupName = $resourceGroupName
        Location = $location
        IPconfiguration = $ipconfig
        tag = $tags
        Force = [switch]$true
    }
    
    $vnic = New-AzNetworkInterface @vNicParamSplat

    Write-Verbose "Creating Virtual Machine"

    $vmConfigParamSplat = @{
        VMName = $resoureName
        VMSize = $vmSizeTable[$vmSize]
        IdentityType = "SystemAssigned"
    }
    $vm = New-AzVMConfig @vmConfigParamSplat

    Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $resoureName -Credential $localCred
    Add-AzVMNetworkInterface -VM $vm -Id $vnic.Id -Primary
    Set-AzVMSourceImage -VM $vm -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2012-R2-Datacenter' -Version latest -Debug

    $vmParamSplat = @{
        ResourceGroupName = $resourceGroupName
        Location = $location
        VM = $vm
        tag = $tags

    }
    New-AzVM @vmParamSplat

}