#!/bin/bash

# shellcheck disable=SC2154

section_break="********************************************"
az_sub="67462158-39cf-4638-9f39-964193f1423e"

vm_rg="nic-rename-rg"
vm_name="nic-rename-vm"
new_nic_name="nic-rename-nic-renamed"
network_rg="nic-rename-network-rg"
network_name="nic-rename-network"
subnet_name="internal"

echo $vm_rg
echo $new_nic_name
echo $network_rg

# Azure login and set subscription
echo "${section_break}"
echo "Connecting to Azure"
echo "${section_break}"
az login
az account set --subscription "${az_sub}"

# Get VM
echo "${section_break}"
echo "Getting VM Details"
echo "${section_break}"
az vm show -g "$vm_rg" -n "$vm_name"


# Get NIC associated with the VM
echo "${section_break}"
echo "Getting NIC details of VM ${vm_name}"
echo "${section_break}"

echo "$vm_rg"
echo "$vm_name"

old_nic_id=$(az vm show -g "$vm_rg" -n "$vm_name" --query "networkProfile.networkInterfaces[].id" -otsv)
echo "$old_nic_id"
old_nic_name="$(az network nic list --resource-group "$vm_rg" --query "[0].name" -otsv)"
echo "$old_nic_name"

az network nic show --resource-group "$vm_rg" --name "$old_nic_name" --ids "$old_nic_id"

# Stop the Azure VM if it is running
echo "${section_break}"
echo "Checking if VM is running"
echo "${section_break}"
vm_status=$(az vm show -g "${vm_rg}" -n "${vm_name}" -d --query "powerState")

if [[ "$vm_status" == "VM running" ]]; then
    echo "${section_break}"
    echo "VM ${vm_name} is running - deallocating to allow for new NIC creation"
    echo "${section_break}"
    az vm deallocate --resource-group ${vm_rg} --name $vm_name
    echo "VM Deallocated Successfully"
fi

#Create the new NIC Interface
echo "${section_break}"
echo "Creating the New virtual network interface"
echo "${section_break}"

az network nic create --resource-group "$network_rg" --name "$new_nic_name" --vnet-name "$network_name" --subnet "$subnet_name" --location="$azure_location"

echo "${section_break}"
echo "New NIC ${new_nic_name} created successfully"
echo "${section_break}"

# Intermediate step to move new NIC to required resource group - consider using az network nic show instead
echo "${section_break}"
echo "Attempting to move new NIC to desired resource group"
echo "${section_break}"

new_nic_id="/subscriptions/${az_sub}/resourceGroups/${network_rg}/providers/Microsoft.Network/networkInterfaces/${new_nic_name}"
az resource move --destination-group "$vm_rg" --ids "${new_nic_id}"

echo "${section_break}"
echo "NIC Successfully moved to ${vm_rg}"
echo "${section_break}"

# Attach the New NIC
echo "${section_break}"
echo "Attempting to attach new NIC to VM ${vm_rg}"
echo "${section_break}"

# Detach the old NIC from the VM
echo "${section_break}"
echo "Attempting to detach old NIC from VM ${vm_rg}"
echo "${section_break}"

# Delete the old NIC
echo "${section_break}"
echo "Attempting to delete old  NIC"
echo "${section_break}"

# Start the VM back up
echo "${section_break}"
echo "Starting Virtual Machine back up, please wait....."
echo "${section_break}"
az vm start --resource-group "$vm_rg" --name "$vm_name"
