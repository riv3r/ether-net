provider "aws" {
  region = var.aws_region
}

# provider "checkpoint" {

#   server   = data.aws_instance.management_server.public_ip
#   username = "admin"
#   password = var.cp_passwd
#   context  = "web_api"
# }