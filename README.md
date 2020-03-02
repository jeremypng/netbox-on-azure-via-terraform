# Azure NetBox Deployment via Terraform

On Mac:

1. brew update && brew install azure-cli
2. az login
3. modify subnet in netbox-az-cloud.tf
4. copy ~/.ssh/id_rsa.pub to key_data, use ssh-keygen if you don't have an ssh key
4. run terraform init
5. run terraform plan
6. run terraform apply
7. ssh azureuser@<ip output by apply>
8. sudo apt-get update && sudo apt-get upgrade && sudo apt-get autoremove
9. curl https://raw.githubusercontent.com/jeremypng/netbox-on-azure-via-terraform/master/netbox-install.sh | sudo su - bash

