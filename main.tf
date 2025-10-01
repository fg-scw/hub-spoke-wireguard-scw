terraform {
  required_version = ">= 1.5.0"
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 2.29.0"
    }
    wireguard = {
      source  = "OJFord/wireguard"
      version = ">= 0.3.8"
    }
  }
}

provider "scaleway" {
  access_key = var.scaleway_access_key
  secret_key = var.scaleway_secret_key
  project_id = var.scaleway_project_id
  region     = var.region
  zone       = var.zone
}

# Clés WireGuard
resource "wireguard_asymmetric_key" "hub" {}
resource "wireguard_asymmetric_key" "spoke01" {}
resource "wireguard_asymmetric_key" "spoke02" {}
