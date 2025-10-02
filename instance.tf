# IPs publiques pour Wireguard
resource "scaleway_instance_ip" "wg_ips" {
  for_each = local.wg_instances
  zone     = var.zone
}

# Instances Wireguard avec configuration NAT optimisée
resource "scaleway_instance_server" "wg_instances" {
  for_each = local.wg_instances
  
  name              = each.value.name
  type              = each.value.type
  image             = "ubuntu_noble"
  zone              = var.zone
  ip_id             = scaleway_instance_ip.wg_ips[each.key].id
  security_group_id = scaleway_instance_security_group.wireguard.id
  
  user_data = {
    "cloud-init" = templatefile(
      each.key == "hub" ? 
        "${path.module}/cloud-init/wireguard-hub-nat-corrected.yaml" : 
        each.key == "spoke_02" ?
        "${path.module}/cloud-init/wireguard-spoke02-nat-corrected.yaml" :
        "${path.module}/cloud-init/wireguard-spoke01-corrected.yaml",
      {
        wg_private_key = local.wg_keys[each.key].private
        wg_local_ip    = local.wg_ips[each.key]
        wg_port        = var.wireguard_port
        wg_mtu         = var.wireguard_mtu
        ssh_public_key = var.ssh_public_key
        peers = [
          for peer in each.value.peers : {
            public_key  = peer.public_key
            allowed_ips = peer.allowed_ips
            endpoint    = "${scaleway_instance_ip.wg_ips[peer.endpoint_ref].address}:${var.wireguard_port}"
          }
        ]
      }
    )
  }
  
  tags = concat(
    ["wireguard", each.key, "vpn"],
    each.key == "hub" ? ["nat-gateway"] : []
  )
}

# Attachements réseaux pour instances Wireguard
resource "scaleway_instance_private_nic" "wg_primary_nics" {
  for_each = local.wg_instances
  
  server_id = scaleway_instance_server.wg_instances[each.key].id
  zone      = var.zone
  private_network_id = (
    each.key == "spoke_02" ? 
    scaleway_vpc_private_network.spoke_02_networks["a"].id :
    scaleway_vpc_private_network.simple_networks[each.key].id
  )
}

# Attachement réseau supplémentaire pour spoke_02 (réseau B)
resource "scaleway_instance_private_nic" "wg_spoke_02_nic_b" {
  server_id          = scaleway_instance_server.wg_instances["spoke_02"].id
  private_network_id = scaleway_vpc_private_network.spoke_02_networks["b"].id
  zone               = var.zone
  
  depends_on = [scaleway_instance_private_nic.wg_primary_nics]
}

# Instance client PostgreSQL avec routage via WireGuard
resource "scaleway_instance_server" "postgres_client" {
  name              = "postgres-client-spoke02"
  type              = "PLAY2-MICRO"
  image             = "ubuntu_noble"
  zone              = var.zone
  security_group_id = scaleway_instance_security_group.client.id
  
  user_data = {
    "cloud-init" = templatefile("${path.module}/cloud-init/postgres-client-simplified.yaml", {
      ssh_public_key = var.ssh_public_key
      db_endpoint    = scaleway_rdb_instance.postgres_spoke01.private_network[0].ip
      db_port        = scaleway_rdb_instance.postgres_spoke01.private_network[0].port
      db_name        = "rdb"
      db_password    = random_password.db_password.result
    })
  }

  tags = ["postgres", "client", "spoke02", "wireguard-routed"]

  depends_on = [
    scaleway_rdb_instance.postgres_spoke01,
    scaleway_instance_server.wg_instances
  ]
}

# Attachement réseau pour client PostgreSQL
resource "scaleway_instance_private_nic" "postgres_client_pn" {
  server_id          = scaleway_instance_server.postgres_client.id
  private_network_id = scaleway_vpc_private_network.spoke_02_networks["a"].id
  zone               = var.zone
  
  depends_on = [scaleway_instance_server.postgres_client]
}