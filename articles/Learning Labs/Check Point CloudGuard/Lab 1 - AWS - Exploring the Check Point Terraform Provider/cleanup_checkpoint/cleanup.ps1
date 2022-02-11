terraform state rm -state="..\terraform.tfstate" checkpoint_management_access_rule.drop_ssh_bastion_to_fws
terraform state rm -state="..\terraform.tfstate" checkpoint_management_host.bastion
terraform state rm -state="..\terraform.tfstate" checkpoint_management_host.protected_host
terraform state rm -state="..\terraform.tfstate" checkpoint_management_install_policy.exercise2
terraform state rm -state="..\terraform.tfstate"  checkpoint_management_install_policy.exercise3
terraform state rm -state="..\terraform.tfstate" checkpoint_management_login.login
terraform state rm -state="..\terraform.tfstate" checkpoint_management_publish.exercise2
terraform state rm -state="..\terraform.tfstate" checkpoint_management_publish.exercise3
terraform state rm -state="..\terraform.tfstate" checkpoint_management_simple_gateway.terraformer_fw
Remove-Item -Path "..\fingerprints.json", "..\sid.json"
Remove-Item -Path "..\terraform.tfstate.*.backup"