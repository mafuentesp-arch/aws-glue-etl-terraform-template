terraform {
  required_version = "= 1.17.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.100.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
      Owner     = var.owner
    }
  }
}

data "aws_caller_identity" "current" {}

