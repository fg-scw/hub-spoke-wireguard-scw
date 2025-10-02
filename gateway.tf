resource "scaleway_vpc_public_gateway_ip" "gw_ip" {
  zone = var.zone
}

resource "scaleway_vpc_public_gateway" "main_gateway" {
  name            = "pgw-wg-mesh"
  type            = "VPC-GW-S"
  ip_id           = scaleway_vpc_public_gateway_ip.gw_ip.id
  zone            = var.zone
  bastion_enabled = true
  enable_smtp     = false
  
  tags = ["gateway", "ssh", "bastion"]
}

# Attachements gateway aux réseaux - PAS de route par défaut
resource "scaleway_vpc_gateway_network" "gw_networks" {
  for_each = merge(
    scaleway_vpc_private_network.simple_networks,
    scaleway_vpc_private_network.spoke_02_networks
  )
  
  gateway_id         = scaleway_vpc_public_gateway.main_gateway.id
  private_network_id = each.value.id
  zone               = var.zone
  
  ipam_config {
    # IMPORTANT: false car on route via WireGuard
    push_default_route = false
  }
  
  # Masquerade désactivé car NAT fait par WireGuard
  enable_masquerade = false
}