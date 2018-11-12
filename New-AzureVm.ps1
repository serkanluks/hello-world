$cred = get-credential
login-azurermaccount -Credential $cred

New-AzureRmResourceGroup -ResourceGroupName "SLResouuceGroup1" -Location "EastUS"
New-AzureRmResourceGroup -name MyResrouceGroup -Location "eastus"

# Create new Azure RMVM 
New-AzureRmVM `
-ResourceGroupName "MyResourceGroup" `
-Name "SLVM1" `
-Location 'East US' `
-VirtualNetworkName "SLNet" `
-SubnetName "SLSubnet" `
-SecurityGroupName "SLSng" `
-PublicIpAddressName "SL1publicIP" `
-Credential $cred -AsJob

# Retrieve the Public IP Address
Get-AzureRmPublicIpAddress -name SL1publicIP -ResourceGroupName myresourcegroup | select ipaddress

#Find publisher/sku/offer from marketplace to deploy custom OS
Get-AzureRmVMImagePublisher -Location 'East US' -
Get-AzureRmVMImageOffer -location 'East US'-PublisherName microsoftwindowsserver
Get-AzureRmVMImageSku -Location 'East US' -PublisherName microsoftwindowsserver -Offer windowsserver

#Deploy VM with specific image from marketplace
New-AzureRmVM `
-ResourceGroupName "MyResourceGroup" `
-Name "SLVM2" `
-Location 'East US' `
-VirtualNetworkName "SLNet" `
-SubnetName "SLSubnet" `
-SecurityGroupName "SLSng" `
-PublicIpAddressName "SL2publicIP" `
-ImageName "MicrosoftWindowsServer:WindowsServer:2016-Datacenter:latest" `
-Credential $cred `
-AsJob `
-Verbose

#Create Data disk config
$diskconfig = New-AzureRmDiskConfig `
-Location 'East US' `
-CreateOption empty `
-DiskSizeGB 128

#Create Data disk
$datadisk = New-AzureRmDisk `
-ResourceGroupName "myresourcegroup" `
-diskname "datadisk" `
-disk $diskconfig  

get-azurermdisk -ResourceGroupName 'myresourcegroup' -diskname 'datadisk'

#Attach data disk to VM
$VM = get-azurermvm -ResourceGroupName 'myresourcegroup' -name "SLVM1"
$VM = Add-AzureRmVMDataDisk `
-vm $vm `
-name "datadisk" `
-CreateOption attach `
-manageddiskid $datadisk.id `
-Lun 1

#Update VM with new datadisk
update-azurermvm -ResourceGroupName 'MyresourceGroup' -VM $VM
get-disk | where parttionstyle -eq 'raw' | `
new-partition -assigndriveletter -usemaximumsize | `
format-volume -filesystem NTFS -newfilesystemlabel "Datadisk" -confirm:$false

#Get VM size by location
Get-AzureRmVMSize -Location 'East US'
#Check the available VM sizes in the cluster the VM lives
#If availalbe you can re-size the VM while the VM running. If not 
#available you have to re-allocate the VM.
$VM = Get-AzureRmVMSize -ResourceGroupName 'myresourcegroup' -VMName 'SLVM1'
#Resize the VM
$VM.HardwareProfile.VmSize = "Standard_DS2_V2"
#Update the VM
Update-AzureRmVM -VM $VM -ResourceGroupName 'myresourcegroup'







