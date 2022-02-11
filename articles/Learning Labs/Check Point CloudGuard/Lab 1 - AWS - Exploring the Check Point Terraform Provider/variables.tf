# ========================================================================
# GLOBAL VARIABLES
# ========================================================================

variable "wan_ip" {
  description = "IP address(es) permitted access to public_subnets (e.g.: '123.45.67.89/32,172.10.11.0/24)"
  type        = string
}

variable "keys_algorithm" {
  description = "The encryption algorithm to use for private key generation"
  type        = string
  default     = "RSA"
}

variable "keys_rsa_bits" {
  description = "The number of bits to use with var.keys_alogithm, higher is stronger"
  type        = number
  default     = 2048
}

# ========================================================================
# AWS INIT VARIABLES
# ========================================================================

variable "aws_region" {
  description = "Region to deploy all AWS constructs in"
  type        = string
  default     = "us-east-1"
}

variable "aws_azs" {
  description = "AWS Availability Zone(s) for resources"
  type        = list(string)
  default     = ["us-east-1a"]
}

variable "aws_vpc_name" {
  description = "Name for the VPC infrastructure is being deployed in"
  type        = string
  default     = "security"
}

variable "aws_vpc_cidr" {
  description = "The CIDR block associated with vpc_name"
  type        = string
  default     = "10.80.0.0/16"
}

variable "aws_public_subnet" {
  description = "Publicly accessible subnet, must be derived from vpc_cidr"
  type        = string
  default     = "10.80.240.0/24"
}

variable "aws_protected_subnet" {
  description = "Public subnet that is protected by Check Point CloudGuard Appliance"
  type        = string
  default     = "10.80.250.0/24"
}


# ========================================================================
# AWS EC2 Variables
# ========================================================================

variable "aws_ami_owner_amazon" {
  description = "AWS AMI owner ID for Amazon Linux 2 HVM Kernel 5.10"
  type        = string
  default     = "137112412989"
}

variable "aws_ami_owner_checkpoint" {
  description = "AWS AMI owner ID for Check Point"
  type        = string
  default     = "679593333241"
}

variable "aws_ami_owner_microsoft" {
  description = "AWS AMI owner ID for Microsoft"
  type        = string
  default     = "801119661308"
}

variable "aws_ami_name_amazon_linux" {
  description = "AWS AMI Name for Amazon Linux 2 HVM Kernel 5.10"
  type        = string
  default     = "amzn2-ami-kernel-5.10-hvm-2.0.20220121.0-x86_64-gp2"
}

variable "aws_ami_name_cp_cloudguard" {
  description = "AWS AMI Name for Check Point CloudGuard Appliance"
  type        = string
  default     = "Check Point CloudGuard IaaS GW PAYG-NGTP R80.40-294.983-60f17231-5e1f-4d8b-9381-735a780fcb0f"
}

variable "aws_ami_name_cp_security_management" {
  description = "AWS AMI Name for Check Point Security Management server"
  type        = string
  default     = "Check Point CloudGuard IaaS PAYG-MGMT25 R80.40-294.983-3a503465-b9ae-44ea-85be-ac107b7647a7"
}

variable "aws_ami_name_ms_WinServer2022" {
  description = "AWS AMI Name for Windows Server 2022"
  type        = string
  default     = "Windows_Server-2022-English-Full-Base-2021.12.15"
}

variable "aws_ec2_type_amazon_linux" {
  description = "Amazon Linux 'protected host' AWS instance type"
  type        = string
  default     = "t2.micro"
}

variable "aws_ec2_type_bastion" {
  description = "Bastion server AWS instance type"
  type        = string
  default     = "m4.large"
}

# If instance type RAM < 8GB selected please refer to
# user_data/checkpoint_management.sh optional configuration comments
variable "aws_ec2_type_cp_security_management" {
  description = "Check Point management server AWS instance type"
  type        = string
  default     = "m5.xlarge" # 8GB+ RAM ensures API starts automatically
}

variable "aws_ec2_type_cp_cloudguard" {
  description = "Check Point cloudguard appliance AWS instance type"
  type        = string
  default     = "c5.large"
}

variable "aws_ec2_ntp_primary" {
  description = "Primary NTP Server to use for EC2 instances, defaults to AWS Time Sync Service"
  type        = string
  default     = "169.254.169.123"
}

# ========================================================================
# Check Point Appliance Specific Variables
# ========================================================================

variable "cp_mgmt_hostname" {
  description = "Hostname for the Check Point Management Server"
  type        = string
  default     = "mgmt-svr"
}

variable "cp_fw_hostname" {
  description = "Hostname for the Check Point CloudGuard appliance"
  type        = string
  default     = "cloudguard-fw"
}

variable "cp_timezone" {
  description = "Time zone for Check Point appliances"
  type        = string
  default     = "Australia / Perth"
}

variable "cp_admin_shell" {
  description = "The default admin shell to use on Check Point appliances"
  type        = string
  default     = "/etc/cli.sh"
}

/*
   Do not use plain text passwords outside of demo environments.
   
   Better methods to consider for non-demo environments:
   (1) 'openssl passwd -6 <PASSWORD>' to get the password hash, modify
        userdata/checkpoint_mgmt.sh lines 36-44 to use a hash instead of
        creating a hash from a supplied plain-text password. Secure your hash!
   (2) Use a secrets management tool (e.g.: Hashicorp Vault) to store a hash
       generated from (1) and then access it via a TF provider or API
*/
variable "cp_passwd" {
  description = "Check Point password to use to login and use expert mode."
  type        = string
}

variable "cp_sic" {
  description = "The pre-shared key for secure internal communication (SIC)"
  type        = string
}