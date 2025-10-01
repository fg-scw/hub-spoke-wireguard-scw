########################################
# Managed PostgreSQL (RDB)
########################################

resource "scaleway_rdb_instance" "postgres_spoke01" {
  name              = "postgres-rdb01"
  engine            = "PostgreSQL-16"
  is_ha_cluster     = false
  node_type         = "DB-PLAY2-PICO"
  region            = var.region
  user_name         = var.db_user
  password          = var.db_password
  volume_type       = "sbs_15k"
  volume_size_in_gb = 20

  # Attachement au PN du spoke01
  private_network {
    pn_id       = scaleway_vpc_private_network.spoke01.id
    enable_ipam = true # laisse IPAM choisir l'IP/masque pour le service DB
  }

  tags = ["env:gpt", "role:rdb"]
}

# ACLs RDB : WG + PNs autorisés
resource "scaleway_rdb_acl" "postgres_acl" {
  instance_id = scaleway_rdb_instance.postgres_spoke01.id
  region      = var.region

  acl_rules {
    ip          = "192.168.1.0/24" # réseau WG
    description = "WireGuard network"
  }

  acl_rules {
    ip          = "172.16.10.0/23" # hub PN
    description = "hub PN"
  }

  acl_rules {
    ip          = "172.16.32.0/23" # spoke01 PN
    description = "spoke01 PN"
  }

  acl_rules {
    ip          = "172.16.64.0/23" # spoke02-A PN
    description = "spoke02-A PN"
  }

  acl_rules {
    ip          = "172.16.66.0/23" # spoke02-B PN
    description = "spoke02-B PN"
  }
}
