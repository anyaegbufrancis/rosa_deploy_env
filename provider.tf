

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      environment = var.env
      created_by  = var.created_by
    }
  }
}

terraform {
  required_providers {
    local = {
      version = "~> 2.1"
    }
  }
}
