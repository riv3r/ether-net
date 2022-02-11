# ========================================================================
# Data Lookups
# ========================================================================

data "aws_ami" "cloudguard_mgmt" {

  owners = [var.aws_ami_owner_checkpoint]

  filter {
    name   = "name"
    values = [var.aws_ami_name_cp_security_management]
  }

}

data "aws_ami" "cloudguard_fw" {

  owners = [var.aws_ami_owner_checkpoint]

  filter {
    name   = "name"
    values = [var.aws_ami_name_cp_cloudguard]
  }

}

data "aws_ami" "amazon_linux" {

  owners = [var.aws_ami_owner_amazon]

  filter {
    name   = "name"
    values = [var.aws_ami_name_amazon_linux]
  }

}

data "aws_ami" "windows_server_2022" {

  owners = [var.aws_ami_owner_microsoft]

  filter {
    name   = "name"
    values = [var.aws_ami_name_ms_WinServer2022]
  }

}

data "aws_instance" "bastion" {
  instance_id = module.bastion.id
}

data "aws_instance" "cloudguard_fw" {
  instance_id = module.cloudguard_fw.id
}

data "aws_instance" "protected_host" {
  instance_id = module.protected_host.id
}

data "aws_instance" "management_server" {
  instance_id = module.management_server.id
}

data "aws_network_interface" "cloudguard_eth0" {
  id = aws_network_interface.cloudguard_eth0.id
}

data "aws_network_interface" "cloudguard_eth1" {
  id = aws_network_interface.cloudguard_eth1.id
}


# ========================================================================
# Networking Constructs
#
# We do not use AWS VPC module as it's too difficult to manage the route
# table association with subnets.
# ========================================================================

locals {

  ipv4_mask_length = element(
    split("/", "${aws_subnet.public.cidr_block}"),
    1
  )

}

resource "aws_vpc" "security" {
  cidr_block = var.aws_vpc_cidr

  tags = {
    Name = "Security"
  }

}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.security.id
  cidr_block              = var.aws_public_subnet
  availability_zone       = var.aws_azs[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Public"
  }

}

resource "aws_subnet" "protected" {
  vpc_id                  = aws_vpc.security.id
  cidr_block              = var.aws_protected_subnet
  availability_zone       = var.aws_azs[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Protected"
  }

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.security.id

  tags = {
    Name = "Security IGW"
  }

}

resource "aws_route_table" "ingress" {
  vpc_id = aws_vpc.security.id

  route {
    cidr_block           = var.aws_protected_subnet
    network_interface_id = aws_network_interface.cloudguard_eth0.id
  }

  tags = {
    Name = "Ingress"
  }

}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.security.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id # Known Issue
  }
  route {
    cidr_block           = var.aws_protected_subnet
    network_interface_id = aws_network_interface.cloudguard_eth0.id
  }

  tags = {
    Name = "Public"
  }

}

resource "aws_route_table" "protected" {
  vpc_id = aws_vpc.security.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_network_interface.cloudguard_eth1.id
  }

  tags = {
    Name = "Protected"
  }

}

resource "aws_route_table_association" "ingress_igw" {
  route_table_id = aws_route_table.ingress.id
  gateway_id     = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_route_table_association" "protected" {
  route_table_id = aws_route_table.protected.id
  subnet_id      = aws_subnet.protected.id
}

# ========================================================================
# EC2 - Elastic Network Interfaces - Check Point CloudGuard Firewall
# ========================================================================

resource "aws_eip" "cloudguard_eth0" {

  network_interface = aws_network_interface.cloudguard_eth0.id

  tags = {
    Name = "cloudguard_fw_eth0"
  }

}

resource "aws_network_interface" "cloudguard_eth0" {
  subnet_id         = aws_subnet.public.id
  security_groups   = [module.security_group.security_group_id]
  source_dest_check = false

  tags = {
    Name = "cloudguard_eth0"
  }

}

resource "aws_network_interface" "cloudguard_eth1" {
  subnet_id         = aws_subnet.protected.id
  security_groups   = [module.security_group.security_group_id]
  source_dest_check = false

  tags = {
    Name = "cloudguard_eth1"
  }

}


# ========================================================================
# EC2 Security Group + Instances
# ========================================================================

module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "VPC ${var.aws_vpc_name} SG"
  description = "Security group for Check Point infrastructure"
  vpc_id      = aws_vpc.security.id

  ingress_with_self = [{ rule = "all-all" }]

  ingress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "${var.wan_ip}"
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}


module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name                   = "bastion"
  ami                    = data.aws_ami.windows_server_2022.id
  instance_type          = var.aws_ec2_type_bastion
  key_name               = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids = [module.security_group.security_group_id]
  subnet_id              = aws_subnet.public.id

  tags = {
    Name      = "bastion"
    Terraform = "true"
  }

}


module "protected_host" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name                        = "protected-host"
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.aws_ec2_type_amazon_linux
  key_name                    = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids      = [module.security_group.security_group_id]
  subnet_id                   = aws_subnet.protected.id
  associate_public_ip_address = true

  tags = {
    Name      = "protected-host"
    Terraform = "true"
  }

}


module "cloudguard_fw" {

  depends_on = [
    aws_network_interface.cloudguard_eth0,
    aws_network_interface.cloudguard_eth1
  ]

  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name          = var.cp_fw_hostname
  ami           = data.aws_ami.cloudguard_fw.id
  instance_type = var.aws_ec2_type_cp_cloudguard
  key_name      = aws_key_pair.ec2_key.key_name

  network_interface = [
    {
      device_index                = 0
      network_interface_id        = aws_network_interface.cloudguard_eth0.id
      associate_public_ip_address = true
    },
    {
      device_index                = 1
      network_interface_id        = aws_network_interface.cloudguard_eth1.id
      associate_public_ip_address = false
    }
  ]

  user_data = templatefile("user_data/checkpoint_fw.sh", {
    // script arguments
    cp_fw_hostname = var.cp_fw_hostname,
    cp_passwd      = var.cp_passwd,
    cp_sic         = var.cp_sic,
    cp_shell       = var.cp_admin_shell,
    ntp_primary    = var.aws_ec2_ntp_primary,
    cp_timezone    = var.cp_timezone
  })

  tags = {
    Name      = "cloudguard-fw"
    Terraform = "true"
  }

}


# Provides cloudguard-fw an opportunity to fully come online post reboot
resource "time_sleep" "wait_for_cloudguardfw_reboot" {
  depends_on = [module.cloudguard_fw]

  create_duration = "3m"

}


module "management_server" {

  depends_on = [
    time_sleep.wait_for_cloudguardfw_reboot
  ]

  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name                   = var.cp_mgmt_hostname
  ami                    = data.aws_ami.cloudguard_mgmt.id
  instance_type          = var.aws_ec2_type_cp_security_management
  key_name               = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids = [module.security_group.security_group_id]
  subnet_id              = aws_subnet.public.id
  user_data = templatefile("user_data/checkpoint_mgmt.sh", {
    // script arguments
    cp_mgmt_hostname       = var.cp_mgmt_hostname,
    cp_passwd              = var.cp_passwd,
    cp_sic                 = var.cp_sic,
    cp_shell               = var.cp_admin_shell,
    ntp_primary            = var.aws_ec2_ntp_primary,
    cp_timezone            = var.cp_timezone,
    cp_fw_hostname         = var.cp_fw_hostname,
    cp_fw_private_ip       = data.aws_network_interface.cloudguard_eth0.private_ip,
    cp_fw_protected_ip     = data.aws_network_interface.cloudguard_eth1.private_ip,
    cp_fw_ipv4_mask_length = local.ipv4_mask_length
  })

  tags = {
    Name      = "management-server"
    Terraform = "true"
  }

}


# Prevents initial `terraform apply` from finishing before the Check Point
# Management server has finished the initial configuration process
resource "time_sleep" "wait_for_management_server_initial_config" {
  depends_on = [module.management_server]

  create_duration = "20m"

}