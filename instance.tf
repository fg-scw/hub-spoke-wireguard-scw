########################################
# IP publiques pour hub/spokes
########################################

resource "scaleway_instance_ip" "wg" {
  for_each = local.wg_instances
  zone     = var.zone
}

########################################
# Mapping -> fichiers cloud-init
########################################

locals {
  wg_templates = {
    hub     = "wireguard-hub.yaml"
    spoke01 = "wireguard-spoke01.yaml"
    spoke02 = "wireguard-spoke02.yaml"
  }

  # Map: chaque nœud -> PN principal à attacher au boot
  pn_id_by_node = {
    hub     = scaleway_vpc_private_network.hub.id
    spoke01 = scaleway_vpc_private_network.spoke01.id
    spoke02 = scaleway_vpc_private_network.spoke02_a.id
  }
}

########################################
# WireGuard hub + spokes
########################################

resource "scaleway_instance_server" "wg" {
  for_each = local.wg_instances

  name  = each.value.name
  type  = each.value.type
  image = var.image
  zone  = var.zone

  tags = concat(
    ["role:wireguard", "node:${each.key}"],
    [each.key == "hub" ? "hub" : "spoke"]
  )

  security_group_id = scaleway_instance_security_group.wg.id
  ip_id             = scaleway_instance_ip.wg[each.key].id

  # Attache le PN principal au boot (hub -> PN hub, spoke01 -> PN spoke01, spoke02 -> PN spoke02-A)
  private_network {
    pn_id = local.pn_id_by_node[each.key]
  }

  user_data = {
    cloud-init = templatefile(
      "${path.module}/cloud-init/${local.wg_templates[each.key]}",
      merge(
        {
          ssh_public_key = var.ssh_public_key
          wg_private_key = (
            each.key == "hub"
            ? wireguard_asymmetric_key.hub.private_key
            : (each.key == "spoke01"
              ? wireguard_asymmetric_key.spoke01.private_key
            : wireguard_asymmetric_key.spoke02.private_key)
          )
          wg_local_ip = lookup(local.wg_ips, each.key)
          wg_port     = local.effective_wg_port
          wg_mtu      = local.effective_wg_mtu
        },
        each.key == "hub"
        ? {
          # --- BRANCHE HUB : schéma commun (wg_network_cidr + peers complets)
          wg_network_cidr = local.wg_network_cidr
          local_subnets   = [] # non utilisé côté hub
          peers = tolist([
            for p in local.wg_instances.hub.peers : {
              public_key  = p.public_key
              allowed_ips = p.allowed_ips
              endpoint = format(
                "%s:%d",
                scaleway_instance_ip.wg[p.endpoint_ref].address,
                local.effective_wg_port
              )
            }
          ])
        }
        : {
          # --- BRANCHE SPOKE : schéma commun avec peer HUB
          wg_network_cidr = "" # non utilisé côté spoke
          local_subnets   = each.value.local_subnets
          peers = tolist([
            {
              public_key  = wireguard_asymmetric_key.hub.public_key
              allowed_ips = "" # aligne le schéma avec la branche hub
              endpoint = format(
                "%s:%d",
                scaleway_instance_ip.wg["hub"].address,
                local.effective_wg_port
              )
            }
          ])
        }
      )
    )
  }
}

# NIC secondaire pour spoke02 (réseau B / PN spoke02-b)
resource "scaleway_instance_private_nic" "wg_spoke02_pn_b" {
  server_id          = scaleway_instance_server.wg["spoke02"].id
  private_network_id = scaleway_vpc_private_network.spoke02_b.id
  zone               = var.zone
}

########################################
# Client PostgreSQL dans spoke02 (subnet A)
########################################

resource "scaleway_instance_server" "pg_client" {
  name              = "pg-client"
  type              = var.client_instance_type
  image             = var.image
  zone              = var.zone
  security_group_id = scaleway_instance_security_group.client.id

  # Attache au PN spoke02-A au boot
  private_network {
    pn_id = scaleway_vpc_private_network.spoke02_a.id
  }

  user_data = {
    cloud-init = templatefile(
      "${path.module}/cloud-init/postgres-client.yaml",
      {
        ssh_public_key = var.ssh_public_key

        # passerelle = IP privée RÉELLE du spoke02 sur le PN A (fourni via tfvars)
        spoke_lan_ip   = var.spoke02_lan_ip
        vpc_gateway_ip = var.spoke02_lan_ip

        # routes intra-VPC (ici le subnet B)
        intra_vpc_subnets_joined = join(" ", [local.vpcs.spoke_02.subnets.b])

        db_endpoint = scaleway_rdb_instance.postgres_spoke01.private_network[0].ip
        db_port     = 5432
        db_name     = var.db_name
        db_password = var.db_password
      }
    )
  }
}
