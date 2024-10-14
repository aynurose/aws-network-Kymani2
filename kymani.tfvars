aws_bucket_region      = "us-east-2"           #YOUR_BUCKET_REGION
aws_bucket_name        = "kymani-bucket2"  #YOUR_BUCKET_NAME
deployment_environment = "kymani"           #DEPLOYMENT_ENVIRONMENT
deployment_name        = "aws-network"           #DEPLOYMENT_NAME

aws_network_settings = {
  main-vpc = {
    enabled            = true
    vpc_name           = "main-vpc"
    vpc_cidr           = "11.0.0.0/16"
    azs                = ["us-east-1a", "us-east-1b", "us-east-1c"]
    private_subnets    = ["11.0.1.0/24"]
    public_subnets     = ["11.0.101.0/24"]
    enable_nat_gateway = true
    enable_vpn_gateway = false
    tags = {
      Terraform   = "true"
      Environment = "dev"
    }
  }
}


