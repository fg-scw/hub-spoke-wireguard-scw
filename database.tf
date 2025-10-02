resource "scaleway_rdb_instance" "postgres_spoke01" {
  name           = "postgres-rdb01"
  engine         = "PostgreSQL-16"
  node_type      = "db-play2-pico"
  is_ha_cluster  = false
  region         = var.region
  
  private_network {
    pn_id       = scaleway_vpc_private_network.simple_networks["spoke_01"].id
    enable_ipam = true
  }
  
  user_name             = "dbadmin"
  password              = random_password.db_password.result
  volume_type           = "sbs_5k"
  volume_size_in_gb     = 10
  backup_schedule_frequency = 24
  backup_schedule_retention = 7
  
  tags = ["database", "postgres", "spoke01"]
}

resource "random_password" "db_password" {
  length  = 32
  special = true
  upper   = true
  lower   = true
  numeric = true
  # Assure au minimum 1 de chaque type
  min_special = 1
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

resource "scaleway_rdb_acl" "postgres_vpn_access" {
  instance_id = scaleway_rdb_instance.postgres_spoke01.id
  
  acl_rules {
    ip          = "192.168.1.0/24"
    description = "Allow Wireguard VPN network"
  }
  
  acl_rules {
    ip          = "172.16.0.0/16"
    description = "Allow all VPC private networks"
  }
}
