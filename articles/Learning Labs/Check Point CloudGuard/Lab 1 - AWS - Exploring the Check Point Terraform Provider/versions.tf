terraform {

  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

    # checkpoint = {
    #   source  = "CheckPointSW/checkpoint"
    #   version = "1.6.0"
    # }

    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }

  }

}