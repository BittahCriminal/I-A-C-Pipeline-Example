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

function ConvertInt64toIP {
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
        [string]$vNetResourceGroupName,

        [Parameter(Mandatory = $false)]
        [int]$numberOfDisks = 2,

        [Parameter()]
        [switch]$publicIp = [switch]$false

    )

    Write-Verbose -Message "Creating virtual Network if applicable"
    if ($vNetName) {
        New-AzVirtualNetwork -Name $vNetName -ResourceGroupName $vNetResourceGroupName -Location $location -AddressPrefix
    }

    Write-Verbose -Message "Setting up IP Configurations"
    $ipConfigParamSplat = @{

    }
    
    New-AzNetworkInterfaceIpConfig -Name "primary" -PrivateIpAddressVersion IPv4 -Primary -SubnetId $subnetResourceId
}