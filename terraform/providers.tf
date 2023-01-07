terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.49.0"
    }

    local = {
      version = "2.2.3"
    }
  }
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      managed_by = "terraform"
    }
  }
}
