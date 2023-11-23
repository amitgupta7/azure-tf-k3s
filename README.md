# azure-tf-k3s
Small script to setup a quick k3s cluster with master and worker nodes. By default, this will setup a two node cluster (with one master, and one worker node). It is configureable to multi node cluster by specifying the `vm_map` input. 

The script needs terraform and azure cli to run. These can be installed using a packet manager like apt (linux) or using homebrew (mac). NOTE: These are mac instructions (homebrew -> terraform --> azure cli). Provided as-is.
```shell
#install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
## install terraform
brew install terraform
## install az cli with brew or pip
brew install azure-cli
## pip install azure-cli && echo PATH=\$PATH:\$HOME/.local/bin >> ~/.bashrc && bash -l
$> az login --use-device-code
## az group create ....
```
## To use the tfscript
Clone `main` branch. 
```shell
$> git clone https://github.com/amitgupta7/azure-tf-k3s.git
$> cd azure-tf-k3s
$> source tfAlias
$> tf init
## provision infra for pods provide EXISTING resource group name,
## azure subscription-id and vm-password on prompt
$> tfaa
## to de-provision provide EXISTING resource group name,
## azure subscription-id and vm-password on prompt
## EXACTLY SAME VALUES AS PROVIDED DURING PROVISIONING
$> tfda
```
## Don't need two VMs (or change other settings)?
The default script will setup two ubuntu nodes with `10.0.2.21` and `10.0.2.22` private_ip_address in `westus2` azure region, running `ubuntu server 20.04 lts` os version. The default machine size is `Standard_D32s_v3` or the recomended 32 vcores - 128gb ram that securiti.ai recommends for `plus` workloads.

The script will prompt for an existing `az_subscription_id`, `az_resource_group` and a strong password (`16 chars alpha-num-special-caps`) as `REQUIRED USER INPUT` to provision the resources.

Note: The `REQUIRED USER INPUT` and other variables like vm os, os disk size, vm-size, subnet cidr etc can also be specified as cli input or local `.tfvars` file. see `var.tf` file for detailed list of variables (and default values) that can be dynamically specified to the script.
```shell
## create a single node cluster
$> tfa -var=vm_map='{"pod1":{"private_ip_address":"10.0.2.21", "role":"master"}}'
## create a two node cluster (default) in eastus2 (instead of default westus2)
tfa -var=location=eastus2
## create a 3 node cluster
$> tfa -var=vm_map='{"pod1":{"private_ip_address":"10.0.2.21", "role":"master"}, "pod2":{"private_ip_address":"10.0.2.22", "role":"worker"}, "pod3":{"private_ip_address":"10.0.2.23", "role":"worker"}}'
```
Alternatively create a `terraform.tfvars` file to override the variables like location, os-image (offer, sku), vm size and vm_map. e.g.
```hcl
az_subscription_id = "azure-subscription-guid"
az_resource_group  = "existing-resource-group"
vm_size            = "Standard_D8s_v3"
os_publisher       = "RedHat"
os_offer           = "RHEL"
os_sku             = "87-gen2"
azpwd              = "strongPwd"
location           = "eastus2"
vm_map             = {"pod1":{"private_ip_address":"10.0.2.21", role = "master"},"pod2":{"private_ip_address":"10.0.2.22", role = "worker"}, "pod3":{"private_ip_address":"10.0.2.23", role = "worker"}}
```
## Output (Run `tfo` to re-print)
NOTE: The script will output the hostnames and mandatory parameters (for resource cleanup run the `tfda` command).
```shell
az_resource_group = "your-az-resource-group"
az_subscription_id = "your-az-subscription-guid-value"
hostnames = [
  "azure-tf-vms-pod1.eastus2.cloudapp.azure.com",
  "azure-tf-vms-pod2.eastus2.cloudapp.azure.com"
]
ssh_credentials = "azuser/yourPasswordStringHere"
```
## Monitoring Appliance Install
The initial run of `tfaa` starts the install as `nohup`, and exits. The intaller script continues the downloads and runs in background on the provisioned servers. If you would like to run a verbose install, use `tfaa && tfaa`, or running `tfaa` again after the initial install, to print install status depening on the status of the install:
* If the `Installer Status: In-Progress`: Running `tfaa` will tail the install log to console . Press `ctrl+c` to stop the tail.
* If the `Installer Status: Completed` Running `tfaa` will print the k8s cluster nodes and service status.
* If the `Installer Status: Error` Running `tfaa` will print the error and the steps to rerun the installer.
* If the `Installer Status: Error` Running `tfaa  -var=clr_lock=true` will reset the error state to `In-Progress` and rerun the installer as `nohup` in background on the provisioned servers. This feature is `Experimental`, and maynot be adequate to perform a clean-up and fresh install. Run `tfda && tfaa` if `tfaa  -var=clr_lock=true` doesn't work.
```
#Run install in verbose mode
tfaa && tfaa
```
