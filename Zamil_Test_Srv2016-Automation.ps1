##################################################################################
#                             NOTE!                                              #
#                                                                                #
#       This Script will create a New Windows 10 Pro                             #
#                                                                                #
#                             BUT                                                #
#       This will use the existing RG, vNet, NSG and Subnet.                     #
#                                                                                #
#                             AND                                                #
#       Create new Public-ip (Dynamic) and a nic.                                #
#       The VM size is Standard_DS2_v2.                                          #
#                                                                                #
#                        Created By Zamil Abedin                                 #
#                                                                                #
##################################################################################

# Variables for common values- Names are editable
$resourceGroup = "Automation"
$location = "northeurope"
$InputRange = 1..10
$Number = $InputRange
$vmName = "DC-$(Get-Random -InputObject $Number)"

# Create user object
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

# Create a resource group
New-AzureRmResourceGroup -Name $resourceGroup -Location $location

# Create a subnet configuration
$subnetConfig = Get-AzureRmVirtualNetworkSubnetConfig -Name Subnet1 -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
  -Name $resourceGroup-vNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name $vmName-ip -AllocationMethod Dynamic -IdleTimeoutInMinutes 4

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = Get-AzureRmNetworkSecurityRuleConfig -Name $resourceGroup-NSG  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 3389 -Access Allow

# Create a network security group
$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
  -Name $resourceGroup-NSG -SecurityRules $nsgRuleRDP

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzureRmNetworkInterface -Name $vmName-Nic -ResourceGroupName $resourceGroup -Location $location `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize Standard_DS2_v2 | `
Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version latest | `
Add-AzureRmVMNetworkInterface -Id $nic.Id

# Create a virtual machine
New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig