# SG WireGuard
resource "scaleway_instance_security_group" "wg" {
  name                    = "sg-wireguard"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  # WireGuard UDP
  inbound_rule {
    action   = "accept"
    protocol = "UDP"
    port     = local.effective_wg_port
    ip_range = "0.0.0.0/0"
  }

  # SSH
  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = 22
    ip_range = "0.0.0.0/0"
  }

  # ICMP
  inbound_rule {
    action   = "accept"
    protocol = "ICMP"
    ip_range = "0.0.0.0/0"
  }
}

# SG Clients
resource "scaleway_instance_security_group" "client" {
  name                    = "sg-client"
  inbound_default_policy  = "accept"
  outbound_default_policy = "accept"
}
