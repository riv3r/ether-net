# !!!!!!!!!!!!!!!!!!!!!!
# REQUIRED FOR ALL DEMOS
# !!!!!!!!!!!!!!!!!!!!!!

# resource "checkpoint_management_login" "login" {
#   depends_on = [
#       time_sleep.wait_for_management_server_initial_config
#     ]

#   user      = "admin"
#   password  = var.cp_passwd
#   read_only = false
# }

# ==================================================================
# EXERCISE 1: Explore existing configuration of cloudguard_fw
# ==================================================================

# data "checkpoint_management_simple_gateway" "cloudguard-fw" {
#   name = "cloudguard-fw"
# } 


# =======================================================================
# EXERCISE 2: Create Firewall, Bootstrap, Onboard into Management Server
# =======================================================================

# module "terraformer_fw" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 3.0"

#   name                        = "terraformer-fw"
#   ami                         = data.aws_ami.cloudguard_fw.id
#   instance_type               = var.aws_ec2_type_cp_cloudguard
#   key_name                    = aws_key_pair.ec2_key.key_name
#   vpc_security_group_ids      = [module.security_group.security_group_id]
#   subnet_id                   = aws_subnet.public.id
#   associate_public_ip_address = false

#   user_data = templatefile("user_data/checkpoint_fw.sh", {
#     // script arguments
#     cp_fw_hostname = "terraformer-fw",
#     cp_passwd      = var.cp_passwd,
#     cp_sic         = var.cp_sic,
#     cp_shell       = var.cp_admin_shell,
#     ntp_primary    = var.aws_ec2_ntp_primary,
#     cp_timezone    = var.cp_timezone
#   })

#   tags = {
#     Name      = "terraformer-fw"
#     Terraform = "true"
#   }

# }

# # Forces wait for firewall to restart and come back online
# resource "time_sleep" "wait_for_terraformerfw_reboot" {
#   depends_on = [module.terraformer_fw]

#   create_duration = "3m"

# }

# resource "checkpoint_management_simple_gateway" "terraformer_fw" {

#   depends_on = [
#     checkpoint_management_login.login,
#     time_sleep.wait_for_terraformerfw_reboot
#   ]

#   name              = "terraformer-fw"
#   ipv4_address      = module.terraformer_fw.private_ip
#   one_time_password = var.cp_sic
#   version           = "R80.40"
#   os_name           = "Gaia"
#   color             = "black"
#   firewall          = true
#   ips               = false

#   # Automatically created attributes, specify to avoid TF raising these as modified attributes every plan/apply cycle
#   send_logs_to_server = ["${var.cp_mgmt_hostname}"]
#   logs_settings = {
#     before_delete_run_script_command      = ""
#     alert_when_free_disk_space_below_type = "popup alert"
#   }

#   interfaces {
#     name             = "eth0"
#     ipv4_address     = module.terraformer_fw.private_ip
#     ipv4_mask_length = local.ipv4_mask_length
#     topology         = "external"
#     security_zone    = false
#     anti_spoofing    = false
#   }

# }

# resource "checkpoint_management_publish" "exercise2" {

#   depends_on = [
#      checkpoint_management_login.login,
#      checkpoint_management_simple_gateway.terraformer_fw
#   ]

# }

/*
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                           READ ME
    DO NOT UNCOMMENT checkpoint_management_install_policy yet!
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   checkpoint_management_simple_gateway resource does not automatically
   initiate SIC. This is REQUIRED for the Security Management Server to
   manage "terraformer-fw".

   Perform the following before installing the policy:
   (1) RDP to Bastion and open/login to Check Point SmartConsole 
   (2) In "Gateways & Servers" double-click on "terraformer-fw"
   (3) On the "General Properties" section click the button "Communication..."
   (4) Enter the value of var.cp_sic in the one-time-password fields twice and
       then click "Initialize" - a success message will appear
   (5) Click on the "Publish" button in the top middle of the application
   (6) Now uncomment the below code and run it in Terraform 
*/

# resource "checkpoint_management_install_policy" "exercise2" {

#   depends_on = [
#     checkpoint_management_publish.exercise2
#   ]

#   policy_package    = "standard"
#   threat_prevention = false
#   desktop_security  = false
#   qos               = false

#   targets = ["terraformer-fw"]

# }

# =====================================================================
# EXERCISE 3: Create Bastion host object & drop SSH from bastion to FWs
# =====================================================================

# resource "checkpoint_management_host" "bastion" {
#   depends_on = [
#     checkpoint_management_login.login,
#   ]

#   name         = "bastion"
#   ipv4_address = data.aws_instance.bastion.private_ip
# }

# resource "checkpoint_management_host" "protected_host" {
#   depends_on = [
#     checkpoint_management_login.login,
#   ]

#   name         = "protected-host"
#   ipv4_address = data.aws_instance.protected_host.private_ip

# }

# resource "checkpoint_management_access_rule" "drop_ssh_bastion_to_fws" {

#   depends_on = [
#     checkpoint_management_host.bastion,
#     checkpoint_management_host.protected_host
#   ]

#   name        = "Drop SSH from Bastion to to Protected Host"
#   layer       = "Network"
#   position    = { top = "top" }
#   source      = ["bastion"]
#   destination = ["protected-host"]
#   service     = ["ssh", "ssh_version_2"]
#   action      = "Drop"

#   track = {
#     type = "Log"
#   }

# }

# resource "checkpoint_management_publish" "exercise3" {

#   depends_on = [
#     checkpoint_management_access_rule.drop_ssh_bastion_to_fws
#   ]

# }

# resource "checkpoint_management_install_policy" "exercise3" {

#   depends_on = [
#     checkpoint_management_publish.exercise3
#   ]

#   policy_package    = "standard"
#   threat_prevention = false
#   desktop_security  = false
#   qos               = false

#   targets = [
#     "cloudguard-fw",
#     "terraformer-fw"
#   ]

# }