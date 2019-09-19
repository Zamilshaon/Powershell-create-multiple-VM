##################################################################################
#                                     NOTE!                                      #
#                                                                                #
#       This Script will create 2 New Windows 10 Pro and 1 SQL Server            #
#       This will create a New RG, 1 vNet, 2 Subnet (Front/Back),                #
#                    3 Public-ip (Dynamic), 1 NSG and 3 nic.                     #
#                      The VM sizes are Standard_DS2_v2.                         #
#                                                                                #
#                        Created By Zamil Abedin                                 #
#                                                                                #
##################################################################################

# Add-AzureRmAccount

$rgName="Zamil"
$location="northeurope"

# Create a resource group.
New-AzureRmResourceGroup -Name $rgName -Location $location

# Subnet configuration
$subnet1config = New-AzureRmVirtualNetworkSubnetConfig -Name "SubnetFrontEnd" -AddressPrefix "192.168.1.0/24"
$subnet2config = New-AzureRmVirtualNetworkSubnetConfig -Name "SubnetBackEnd" -AddressPrefix "192.168.2.0/24"


# Create the VNet with the subnet configurations
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $rgName-vNet -AddressPrefix '192.168.0.0/16' -Location $location -Subnet $subnet1config, $subnet2config


# Create Public IP addresses for the virtual machines
$VM1pubip = New-AzureRmPublicIpAddress -ResourceGroupName $rgName -Name "VM1-pubip" -location $location -AllocationMethod Dynamic 
$VM2pubip = New-AzureRmPublicIpAddress -ResourceGroupName $rgName -Name "VM2-pubip" -location $location -AllocationMethod Dynamic
$SQL1pubip = New-AzureRmPublicIpAddress -ResourceGroupName $rgName -Name "SQL1-pubip" -location $location -AllocationMethod Dynamic

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name $rgName-NSG  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 3389 -Access Allow

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Location $location `
  -Name $rgName-NSG -SecurityRules $nsgRuleRDP


# Create NICs for the virtual machines
$VM1nic = New-AzureRmNetworkInterface -ResourceGroupName $rgName -Location $location -Name "VM1-nic"  -Subnet $vnet.Subnets[0] -PublicIpAddress $VM1pubip -NetworkSecurityGroup $nsg
$VM2nic = New-AzureRmNetworkInterface -ResourceGroupName $rgName -Location $location -Name "VM2-nic"  -Subnet $vnet.Subnets[0] -PublicIpAddress $VM2pubip -NetworkSecurityGroup $nsg
$SQL1nic = New-AzureRmNetworkInterface -ResourceGroupName $rgName -Location $location -Name "SQL1-nic"  -Subnet $vnet.Subnets[1] -PublicIpAddress $SQL1pubip -NetworkSecurityGroup $nsg


############################################################################


# Acquire Server credentials
$servercred = Get-Credential -Message "Enter a username and password for the servers"

# Create Server 1, 2 & 3
$VM1Config = New-AzureRmVMConfig -VMName "VM1" -VMSize "Standard_DS2_v2" | `
  Set-AzureRmVMOperatingSystem -Windows -ComputerName "VM1" -Credential $servercred | `
  Set-AzureRmVMSourceImage -PublisherName "MicrosoftWindowsDesktop" -Offer "Windows-10" -Skus "rs4-pro" -Version latest | `
  Set-AzureRmVMBootDiagnostics -Disable | Add-AzureRmVMNetworkInterface -Id $VM1nic.Id 

$VM2Config = New-AzureRmVMConfig -VMName "VM2" -VMSize "Standard_DS2_v2" | `
  Set-AzureRmVMOperatingSystem -Windows -ComputerName "VM2" -Credential $servercred | `
  Set-AzureRmVMSourceImage -PublisherName "MicrosoftWindowsDesktop" -Offer "Windows-10" -Skus "rs4-pro" -Version latest | `
  Set-AzureRmVMBootDiagnostics -Disable | Add-AzureRmVMNetworkInterface -Id $VM2nic.Id 

$SQL1Config = New-AzureRmVMConfig -VMName "SQL1" -VMSize "Standard_DS2_v2" | `
  Set-AzureRmVMOperatingSystem -Windows -ComputerName "SQL1" -Credential $servercred | `
  Set-AzureRmVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2016-Datacenter" -Version latest | `
  Set-AzureRmVMBootDiagnostics -Disable | Add-AzureRmVMNetworkInterface -Id $SQL1nic.Id 



$VM1 = New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $VM1Config 
$VM2 = New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $VM2Config
$SQL1 = New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $SQL1Config


# Remove Resource Group
# Remove-AzureRmResourceGroup -Name $rgName


#############################################################
# Some helpful cmdlets 

## Get all resopurce groups in the Subscription
# Get-AzureRmResourceGroup

## Get Azure VNet information
# Get-AzureRmVirtualNetwork -ResourceGroupName rangervnetrg -Name myvnet

## Get all Azure Public IP Addresses
# Get-AzureRmPublicIpAddress

## Get all Azure Network Interfaces 
# Get-AzureRmNetworkInterface