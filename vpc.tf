locals {
  aws_network_enabled = true
  aws_network_settings = {
    main-vpc = {
      enabled            = true
      vpc_name           = "main-vpc"
      vpc_cidr           = "10.0.0.0/16"
      azs                = ["us-east-1a", "us-east-1b", "us-east-1c"]
      private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
      enable_nat_gateway = true
      enable_vpn_gateway = true
      tags = {
        Terraform   = "true"
        Environment = var.deployment_environment
      }
    }
  }
  # Ensure both sides return a map of objects
  actual_network_deploy = length(var.aws_network_settings) > 0 ? var.aws_network_settings : { main-vpc = local.aws_network_settings.main-vpc }
  # actual_network_deploy = length(var.aws_network_settings) > 0 ? var.aws_network_settings : local.aws_network_settings
}

module "vpc" {
  for_each           = { for key, value in local.actual_network_deploy : key => value if value.enabled && local.aws_network_enabled }
  source             = "terraform-aws-modules/vpc/aws"
  version            = "5.9.0"
  name               = coalesce(each.value.vpc_name, "main-vpc")
  cidr               = coalesce(each.value.vpc_cidr, "10.0.0.0/16")
  azs                = coalesce(each.value.azs, ["us-east-1a", "us-east-1b", "us-east-1c"])
  private_subnets    = coalesce(each.value.private_subnets, ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"])
  public_subnets     = coalesce(each.value.public_subnets, ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"])
  enable_nat_gateway = coalesce(each.value.enable_nat_gateway, false)
  enable_vpn_gateway = coalesce(each.value.enable_vpn_gateway, false)
  tags               = coalesce(each.value.tags, {})
}

output "debug" {
  value = length(var.aws_network_settings) > 0 ? var.aws_network_settings : { main-vpc = local.aws_network_settings.main-vpc }
}

output "vpc_id" {
  value = { for key, mod in module.vpc : key => mod.vpc_id }
}

output "numbered_public_subnet_ids" {
  value = { for idx, subnet_id in flatten([for key, mod in module.vpc : mod.public_subnets]) : format("public_subnet %d", idx + 1) => subnet_id }
}

output "numbered_private_subnet_ids" {
  value = { for idx, subnet_id in flatten([for key, mod in module.vpc : mod.private_subnets]) : format("private_subnet %d", idx + 1) => subnet_id }
}


