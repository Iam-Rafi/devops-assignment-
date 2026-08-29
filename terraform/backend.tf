terraform {
  backend "s3" {
    bucket       = "terraform-s3-state-log"
    key          = "devops-assignment/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
