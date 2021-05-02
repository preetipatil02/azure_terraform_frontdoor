# azure_terraform_frontdoor
Terraform configuration on Azure to create the frontdoor with path routing

Run terraform init, terraform plan and terraform apply commands from the checked out code at the root level folder.

It is necessary to run "az login" before running the terraform commands. It is possible to provide the subscription_id and tenant_id to the terraform commands, by adding them in the
dev.tf file by setting azure_subscription_id and azure_tenant_id fields.
If not modified it will take what is set in the .azure folder.

The src/ folder gets imported into the dev.tf. Its possible to pass in all the variables to the main.tf in src/ folder via dev.tf to create the
infrastucture for multiple environments. For simplicity all the resources except frontdoor have default values for the variables used to create them.


