########################################
# VPC + Private Networks
########################################

resource "scaleway_vpc" "main" {
  name                             = "main-vpc"
  region                           = var.region
  enable_routing                   = true
  enable_custom_routes_propagation = true
}

# HUB PN (172.16.10.0/23)
resource "scaleway_vpc_private_network" "hub" {
  name   = "pn-hub"
  region = var.region
  vpc_id = scaleway_vpc.main.id

  ipv4_subnet {
    subnet = "172.16.10.0/23"
  }
}

# SPOKE01 PN (172.16.32.0/23)
resource "scaleway_vpc_private_network" "spoke01" {
  name   = "pn-spoke01"
  region = var.region
  vpc_id = scaleway_vpc.main.id

  ipv4_subnet {
    subnet = "172.16.32.0/23"
  }
}

# SPOKE02-A PN (172.16.64.0/23)
resource "scaleway_vpc_private_network" "spoke02_a" {
  name   = "pn-spoke02-a"
  region = var.region
  vpc_id = scaleway_vpc.main.id

  ipv4_subnet {
    subnet = "172.16.64.0/23"
  }
}

# SPOKE02-B PN (172.16.66.0/23)
resource "scaleway_vpc_private_network" "spoke02_b" {
  name   = "pn-spoke02-b"
  region = var.region
  vpc_id = scaleway_vpc.main.id

  ipv4_subnet {
    subnet = "172.16.66.0/23"
  }
}
