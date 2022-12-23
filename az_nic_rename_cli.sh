#!/bin/bash

## Vars needed (input):
placetype=u # u (use place)
placenum_primary=1
placenum_secondary=0 # 0 in this case
azure_location=westeurope # TF_VAR_REGION i.e. westeurope
cust_code=n1dr # n1dr in this case
azure_reg=  # TF_VAR_REGION i.e. westeurope

az_sub=""

## Standard Vars - Set Target Resource Group and New NIC Name

vm_rg_primary=${cust_code}-${placetype}${placenum_primary}-prd-rg
vm_rg_secondary=${cust_code}-${placetype}${placenum_secondary}-prd-rg

new_nic_name=${cust_code}-${placetype}${placenum_secondary}-prd-db1-nic
vm_name_primary=${cust_code}-${placetype}${placenum_primary}-prd-db1
vm_name_secondary=${cust_code}-${placetype}${placenum_secondary}-prd-db1
network_rg_secondary=${cust_code}-${placetype}${placenum_secondary}p-network-rg


echo $vm_rg_primary
echo $vm_rg_secondary
echo $new_nic_name

# Azure login and set subscription
echo "********************************************"
echo "Connecting to Azure"
echo "********************************************"
az login
az account set --subscription "${az_sub}"

# Get VM
echo "********************************************"
echo "Getting VM Details"
echo "********************************************"
az vm show -g "${vm_rg_primary}" -n "${vm_name_primary}" -d
az vm show -g "${vm_rg_secondary}" -n "${vm_name_secondary}" -d

# Get NIC associated with the VM
echo "********************************************"
echo "Getting NIC Details associated with VM"
echo "********************************************"
echo ${vm_rg_secondary}
echo ${vm_name_secondary}
#az vm show -g ${vm_rg_secondary} -n ${vm_name_secondary} -d --query "networkProfile"
#az vm show -g ${vm_rg_secondary} -n ${vm_name_secondary} -d --query "networkProfile.networkInterfaces[0].id"
#old_nic=$(az vm show -g ${vm_rg_secondary} -n ${vm_name_secondary} -d --query "networkProfile")
old_nic_id=$(az vm show -g ${vm_rg_secondary} -n ${vm_name_secondary} -d --query "networkProfile.networkInterfaces[0].id" --output tsv)
#echo $old_nic_id
#old_nic_id=$(echo "$old_nic_id" | tr -d '"')
echo $old_nic_id
old_nic_name=${old_nic_id##*/} # remove all before final /
echo $old_nic_name

# Get the detils of the NIC
#az vm nic show --nic "${old_nic_name}" --resource-group "$vm_rg_secondary" --vm-name "${vm_name_secondary}"
# az network nic ip-config list -g "${vm_rg_secondary}" --nic-name $old_nic_name

# Stop the Azure VM if it is running
echo "********************************************"
echo "Checking if VM is running"
echo "********************************************"
secondary_vm_status=$(az vm show -g "${vm_rg_secondary}" -n "${vm_name_secondary}" -d --query "powerState")

if [[ $vm_status=='VM running' ]]; then
    echo "********************************************"
    echo "VM is running - deallocating to allow for new NIC creation"
    echo "********************************************"
    az vm deallocate --resource-group "${vm_rg_secondary}" --name "${vm_name_secondary}"
    echo "VM Deallocated Successfully"
fi

#Create the new NIC Interface
echo "********************************************"
echo "Creating the New virtual network interface"
echo "********************************************"
az network nic create --resource-group "${network_rg_secondary}" --name "${new_nic_name}" --vnet-name n1dr-u0p-vnet --subnet n1dr-u0p-db-subnet --location="${azure_location}"
echo "********************************************"
echo "New NIC created successfully"
echo "********************************************"


# Intermediate step to move new NIC to required resource group - consider using az network nic show instead
echo "********************************************"
echo "Attempting to move new NIC to desired resource group"
echo "********************************************"

#$new_nic_id=$(az resource show -g n1dr-u0p-network-rg -n $new_nic_name --resource-type "Microsoft.Network/networkInterfaces" --query id --output tsv)
#echo $new_nic_id
##new_nic_id=$(echo "$new_nic_id" | tr -d '"')
#echo $new_nic_id
#new_nic_name=${new_nic_id##*/} # remove all before final /
#echo "${new_nic_name}"
#az resource move --destination-group $vm_rg_secondary --ids $(az resource show -g n1dr-u0p-network-rg -n $new_nic_name --resource-type "Microsoft.Network/networkInterfaces" --query id --output tsv)

# Detach the old NIC from the VM
echo "********************************************"
echo "Attempting to detach old NIC from VM"
echo "********************************************"

#az vm nic remove -g "${vm_rg_secondary}" --vm-name "${vm_name_secondary}" --nics ${old_nic_id}

# Attach the New NIC
echo "********************************************"
echo "Attempting to attach new NIC to VM"
echo "********************************************"
#az vm nic add -g "${vm_rg_secondary}" --vm-name "${vm_name_secondary}" --nics ${new_nic}

# Delete the old NIC
echo "********************************************"
echo "Attempting to delete old  NIC"
echo "********************************************"
# az network nic delete -g "${vm_rg_secondary}" -n "${old_nic_id}"


# Update the New NICs settings for consistency
## DNS Settings
## IP Forwarding
## Accelerated Networking
## Network Security Group
## Tags

# az network nic update
# az network nic ip-config update

# az vm nic set -g MyResourceGroup --vm-name MyVm --nic nic_name1 nic_name2

# Start the VM back up
echo "********************************************"
echo "Starting Virtual Machine back up, please wait....."
echo "********************************************"
az vm start --resource-group "${vm_rg_secondary}" --name "${vm_name_secondary}"
echo "VM Restarted Successfully"