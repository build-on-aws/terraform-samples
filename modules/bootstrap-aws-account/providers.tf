terraform {
  required_version = ">= 1.0" # Or use e.g. ">= 1.9.7" to be more specific

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.2"
    }
  }
}