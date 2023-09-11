# AKSDemo
Azure AKS demo project

This Terrraform scripts provision:
- a small AKS cluster integrated with vnet _spoke1_ and subnet _backend_
- a MS SQL Server attached to vnet _spoke1_ and subnet _db_
- a MS SQL database
- an NSG for the subnet _backend_
- an NSG for the subnet _db_

To run this script you need to have Terraform installed. First, you need to authenticate to Azure. You can authenticate using Azure CLI "az login".
Then you need to create a file (e.g. secret.tfvars) with variable for the database credentials (db_username and db_password).

To provision the infrastructure, run these Terraform commands:
1. terraform init
2. terraform plan -var-file=secret.tfvars
3. terraform apply -var-file=secret.tfvars

After the Terraform scripts run successfully, go to the Azure Portal check the contents of the "aksdemo-rg" resource group.
