variable "deployment_name" {
  type        = string
  default     = "aws-network"
  description = "-(Optional) The name of the deployment"
}

variable "aws_bucket_region" {
  type        = string
  default     = "us-east-1"
  description = "-(Optional) The bucket region default is us-east-1"
}

variable "aws_bucket_name" {
  type        = string
  description = "-(Required) The bucket name is required to store the state file."
}

variable "deployment_environment" {
  type        = string
  default     = "tools"
  description = "-(Optional) The deployment environment name."
}


variable "aws_network_settings" {
  type = map(object({
    enabled            = optional(bool)
    vpc_name           = optional(string)
    vpc_cidr           = optional(string)
    azs                = optional(list(string))
    private_subnets    = optional(list(string))
    public_subnets     = optional(list(string))
    enable_nat_gateway = optional(bool)
    enable_vpn_gateway = optional(bool)
    tags               = optional(map(string))
  }))
  default     = {}
#   description = "-(Optional) Artifact Registry configuration. See [more details](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository)"
}


