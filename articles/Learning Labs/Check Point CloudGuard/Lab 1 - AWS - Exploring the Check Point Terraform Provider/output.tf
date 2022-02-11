output "bastion_public_ip" {
  value = data.aws_instance.bastion.public_ip
}

output "management_server_public_ip" {
  value = data.aws_instance.management_server.public_ip
}

output "management_server_private_ip" {
  value = data.aws_instance.management_server.private_ip
}

output "cloudguard_fw_eth0_public_ip" {
  value = aws_eip.cloudguard_eth0.public_ip
}

output "cloudguard_fw_eth0_private_ip" {
  value = aws_eip.cloudguard_eth0.private_ip
}

output "protected_host_public_ip" {
  value = data.aws_instance.protected_host.public_ip
}

output "protected_host_private_ip" {
  value = data.aws_instance.protected_host.private_ip
}