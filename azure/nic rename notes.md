# NIC Renaming

## Stop the Azure VM if it is running

```shell
echo "Checking if VM is running"
secondary_vm_status=$(az vm show -g "${vm_rg_secondary}" -n "${vm_name_secondary}" -d --query "powerState")

if [[ $vm_status=='VM running' ]]; then
    echo "VM is running - deallocating to allow for new NIC creation"
    az vm deallocate --resource-group "${vm_rg_secondary}" --name "${vm_name_secondary}"
fi
```

## Create the new NIC Interface

```shell
echo "Creating the New virtual network interface"
az network nic create --resource-group n1dr-u0p-network-rg --name "${new_nic_name}" --vnet-name n1dr-u0p-vnet --subnet n1dr-u0p-db-subnet --location="${azure_location}"
```

## Intermediate step to move new NIC to required resource group (possibly?)

```shell
echo "Attempting to move new NIC to desired resource group"
new_nic_id=$(az resource show -g "n1dr-u0p-network-rg" -n "${new_nic_name}" --resource-type "Microsoft.Network/networkInterfaces" --query id)
echo $new_nic_id
new_nic_id=$(echo "$new_nic_id" | tr -d '"')
echo $new_nic_id
new_nic_name=${new_nic##*\"} # remove all before final /
echo $new_nic_name
# az resource move --destination-group "${vm_rg_secondary}" --ids "${new_nic_id}
# az resource move --destination-group "${vm_rg_secondary}" --ids "${new_nic}"
```

## Detach the old NIC from the VM

```shell
# az vm nic remove -g "${vm_rg_secondary}" --vm-name "${vm_name_secondary}" --nics ${old_nic_id}
```

## Attach the New NIC

```shell
az vm nic add -g "${vm_rg_secondary}" --vm-name "${vm_name_secondary}" --nics ${new_nic}`
```

## Delete the old NIC

```shell
az network nic delete -g "${vm_rg_secondary}" -n "${old_nic_id}"
```

## Update the New NICs settings for consistency

### DNS Settings

### IP Forwarding

### Accelerated Networking

### Network Security Group

### Tags

```shell
az network nic update

az network nic ip-config update

az vm nic set -g MyResourceGroup --vm-name MyVm --nic nic_name1 nic_name2
```

## Start the VM back up

```shell
echo "Starting Virtual Machine back up, please wait....."
az vm start --resource-group "${vm_rg_secondary}" --name "${vm_name_secondary}"

az vm nic show -g n1dr-u0-prd-rg --vm-name n1dr-u0-prd-db1 --nic n1dr-u0-prd-db1-nic-2e20ffa8b6b34312ba0da466482991bf

az network nic ip-config list --resource-group n1dr-u0-prd-rg --nic-name n1dr-u0-prd-db1-nic-2e20ffa8b6b34312ba0da466482991bf
```
