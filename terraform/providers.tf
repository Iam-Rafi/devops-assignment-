provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-assignment"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
