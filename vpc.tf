# VPCs
resource "scaleway_vpc" "vpcs" {
  for_each = local.vpcs
  
  name           = each.value.name
  region         = var.region
  tags           = each.value.tags
  enable_routing = true
}

# Réseaux privés - HUB et SPOKE 01 (un réseau chacun)
resource "scaleway_vpc_private_network" "simple_networks" {
  for_each = {
    hub      = local.vpcs.hub
    spoke_01 = local.vpcs.spoke_01
  }
  
  name   = "rpn-${each.key}"
  vpc_id = scaleway_vpc.vpcs[each.key].id
  region = var.region
  tags   = concat(each.value.tags, ["private-network"])
  
  ipv4_subnet {
    subnet = each.value.subnet
  }
}

# Réseaux privés pour SPOKE 02 (deux réseaux)
resource "scaleway_vpc_private_network" "spoke_02_networks" {
  for_each = local.vpcs.spoke_02.subnets
  
  name   = "rpn-spoke-02-${each.key}"
  vpc_id = scaleway_vpc.vpcs["spoke_02"].id
  region = var.region
  tags   = concat(local.vpcs.spoke_02.tags, ["private-network", "network-${each.key}"])
  
  ipv4_subnet {
    subnet = each.value
  }
}
