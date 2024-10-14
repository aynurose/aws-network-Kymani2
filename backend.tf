terraform {
  backend "s3" {
    bucket = "kymani-bucket2"
    key    = "aws-network/kymani/terraform.tfstate"
    region = "us-east-2"
  }
}
