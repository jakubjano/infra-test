##############################################################
# Bastion host
##############################################################

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  create                = var.create_bastion_host
  create_private_key    = true
  key_name              = "bastion-host-private-key"
  private_key_algorithm = "ED25519"
}

resource "aws_security_group" "bastion_host" {
  count = var.create_bastion_host ? 1 : 0

  name        = "${local.app_name_parsed}-bastion-host"
  description = "Allows SSH ingress and database egress traffic"

  vpc_id = var.vpc_id

  ingress {
    description      = "Allows SSH ingress traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description     = "Allows database egress traffic"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.rds_security_group_id]
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  create = var.create_bastion_host
  name   = "${local.app_name_parsed}-bastion-host"

  instance_type               = "t2.micro"
  ami                         = local.bastion_host_ami
  associate_public_ip_address = true

  key_name               = module.key_pair.key_pair_name
  vpc_security_group_ids = [try(aws_security_group.bastion_host[0].id, null)]
  subnet_id              = var.bastion_host_public_subnet_id
}

##############################################################
# VPN
##############################################################

resource "aws_security_group" "vpn" {
  count = var.create_vpn ? 1 : 0

  name        = "${local.app_name_parsed}-vpn"
  description = "Allows VPN ingress and database egress traffic"

  vpc_id = var.vpc_id

  ingress {
    description      = "Allows VPN ingress traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_vpc_security_group_egress_rule" "vpn_rds" {
  count = var.create_vpn ? 1 : 0

  description       = "Allows database egress traffic"
  security_group_id = aws_security_group.vpn[0].id

  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.rds_security_group_id
}

resource "aws_cloudwatch_log_group" "vpn" {
  count = var.create_vpn ? 1 : 0

  name = "${local.app_name_parsed}-vpn"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "vpn" {
  count = var.create_vpn ? 1 : 0

  name = "${local.app_name_parsed}-vpn"

  log_group_name = aws_cloudwatch_log_group.vpn[0].name
}

resource "aws_ec2_client_vpn_endpoint" "this" {
  count = var.create_vpn ? 1 : 0

  client_cidr_block      = "10.1.0.0/16"
  server_certificate_arn = var.vpn_server_certificate_arn
  dns_servers            = ["10.0.0.2"]
  vpc_id                 = var.vpc_id
  security_group_ids     = [aws_security_group.vpn[0].id]
  vpn_port               = 443
  session_timeout_hours  = 8
  split_tunnel           = true

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.vpn_server_certificate_arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn[0].name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn[0].name
  }

  tags = {
    Name = var.app_name
  }
}

resource "aws_ec2_client_vpn_network_association" "this" {
  for_each = var.create_vpn ? toset(var.vpc_subnets) : []

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  subnet_id              = each.value
}

resource "aws_ec2_client_vpn_authorization_rule" "this" {
  count = var.create_vpn && var.vpc_cidr != null ? 1 : 0

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[0].id
  target_network_cidr    = var.vpc_cidr
  authorize_all_groups   = true
}
