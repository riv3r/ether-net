# The resultant private key will be stored unencrypted in the TF state file.
# For any prod environment which is not sandboxed MUST manage keys out of band.
resource "tls_private_key" "keys_pem" {
  algorithm = var.keys_algorithm
  rsa_bits  = var.keys_rsa_bits
}

resource "local_file" "export_private_key" {
  content  = tls_private_key.keys_pem.private_key_pem
  filename = "AccessKey.pem"
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "learner_key"
  public_key = tls_private_key.keys_pem.public_key_openssh
}