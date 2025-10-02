output "public_ips" {
  description = "IPs publiques des instances"
  value = {
    wireguard = {
      for k, v in scaleway_instance_ip.wg_ips : k => v.address
    }
    gateway = scaleway_vpc_public_gateway_ip.gw_ip.address
  }
}

output "database_connection" {
  description = "Informations de connexion à la base de données"
  value = {
    host     = scaleway_rdb_instance.postgres_spoke01.private_network[0].ip
    port     = scaleway_rdb_instance.postgres_spoke01.private_network[0].port
    user     = "dbadmin"
    database = "rdb"
    password = random_password.db_password.result
  }
  sensitive = true
}

# Output séparé pour le mot de passe uniquement
output "database_password" {
  description = "Mot de passe de la base de données"
  value       = random_password.db_password.result
  sensitive   = true
}

output "ssh_commands" {
  description = "Commandes SSH pour accès aux instances"
  value = {
    bastion = "ssh -J bastion@${scaleway_vpc_public_gateway_ip.gw_ip.address} -p 61000"
    direct = {
      for k, v in scaleway_instance_ip.wg_ips : k => "ssh ubuntu@${v.address}"
    }
  }
}

output "wireguard_network" {
  description = "Configuration réseau Wireguard"
  value = {
    network = "192.168.1.0/24"
    nodes = {
      for k, v in local.wg_ips : k => v
    }
    port = var.wireguard_port
  }
}

output "vpn_subnets" {
  description = "Sous-réseaux VPC accessibles via VPN"
  value = {
    hub      = local.vpcs.hub.subnet
    spoke_01 = local.vpcs.spoke_01.subnet
    spoke_02 = local.vpcs.spoke_02.subnets
  }
}

output "wireguard_status_commands" {
  description = "Commandes pour vérifier le statut WireGuard"
  value = {
    for k, v in scaleway_instance_ip.wg_ips : 
    k => "ssh ubuntu@${v.address} 'sudo wg show'"
  }
}