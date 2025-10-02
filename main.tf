terraform {
  required_version = ">= 1.0"
  
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.60.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    wireguard = {
      source  = "OJFord/wireguard"
      version = "~> 0.4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "scaleway" {
}