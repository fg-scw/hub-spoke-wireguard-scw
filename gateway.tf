########################################
# Public Gateway + attachements aux PNs
########################################

# IP publique pour la PGW (zonal)
resource "scaleway_vpc_public_gateway_ip" "pgw_ip" {
  zone = var.zone
}

# Public Gateway
resource "scaleway_vpc_public_gateway" "pgw" {
  name  = "pgw-main"
  type  = "VPC-GW-S"
  zone  = var.zone
  ip_id = scaleway_vpc_public_gateway_ip.pgw_ip.id
  tags  = ["env:gpt", "role:pgw"]
}

# Attaches : PGW reliée aux PNs (pour bastion/accès)
resource "scaleway_vpc_gateway_network" "pgw_hub" {
  gateway_id         = scaleway_vpc_public_gateway.pgw.id
  private_network_id = scaleway_vpc_private_network.hub.id
}

resource "scaleway_vpc_gateway_network" "pgw_spoke01" {
  gateway_id         = scaleway_vpc_public_gateway.pgw.id
  private_network_id = scaleway_vpc_private_network.spoke01.id
}

resource "scaleway_vpc_gateway_network" "pgw_spoke02_a" {
  gateway_id         = scaleway_vpc_public_gateway.pgw.id
  private_network_id = scaleway_vpc_private_network.spoke02_a.id
}

resource "scaleway_vpc_gateway_network" "pgw_spoke02_b" {
  gateway_id         = scaleway_vpc_public_gateway.pgw.id
  private_network_id = scaleway_vpc_private_network.spoke02_b.id
}
