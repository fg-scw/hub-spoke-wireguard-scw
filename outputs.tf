output "wg_public_ips" {
  value = {
    hub     = scaleway_instance_ip.wg["hub"].address
    spoke01 = scaleway_instance_ip.wg["spoke01"].address
    spoke02 = scaleway_instance_ip.wg["spoke02"].address
  }
}

output "wg_overlay_ips" {
  value = local.wg_ips
}

output "rdb_private_ip" {
  value = scaleway_rdb_instance.postgres_spoke01.private_network[0].ip
}

output "spoke02_lan_ip_used_by_clients" {
  value = var.spoke02_lan_ip
}
