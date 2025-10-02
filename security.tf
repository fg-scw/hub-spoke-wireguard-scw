# Règles communes pour tous les groupes
locals {
  common_security_rules = [
    {
      action    = "accept"
      port      = 22
      protocol  = "TCP"
      ip_range  = "0.0.0.0/0"
      desc      = "SSH access"
    },
    {
      action    = "accept"
      protocol  = "ANY"
      ip_range  = "172.16.0.0/16"
      desc      = "Internal VPC traffic"
    },
    {
      action    = "accept"
      protocol  = "ANY"
      ip_range  = "192.168.1.0/24"
      desc      = "Wireguard network traffic"
    }
  ]
}

# Security group pour Wireguard
resource "scaleway_instance_security_group" "wireguard" {
  name                    = "sg-wireguard"
  description            = "Security group for Wireguard VPN instances"
  zone                   = var.zone
  inbound_default_policy = "drop"
  outbound_default_policy = "accept"
  stateful               = true
  
  # Règles communes
  dynamic "inbound_rule" {
    for_each = local.common_security_rules
    content {
      action   = inbound_rule.value.action
      port     = try(inbound_rule.value.port, null)
      protocol = inbound_rule.value.protocol
      ip_range = inbound_rule.value.ip_range
    }
  }
  
  # Règle spécifique Wireguard
  inbound_rule {
    action   = "accept"
    port     = var.wireguard_port
    protocol = "UDP"
    ip_range = "0.0.0.0/0"
  }
}

# Security group pour les clients (sans accès Wireguard direct)
resource "scaleway_instance_security_group" "client" {
  name                    = "sg-client"
  description            = "Security group for client instances"
  zone                   = var.zone
  inbound_default_policy = "drop"
  outbound_default_policy = "accept"
  stateful               = true
  
  # Seulement les règles communes (pas de Wireguard UDP)
  dynamic "inbound_rule" {
    for_each = local.common_security_rules
    content {
      action   = inbound_rule.value.action
      port     = try(inbound_rule.value.port, null)
      protocol = inbound_rule.value.protocol
      ip_range = inbound_rule.value.ip_range
    }
  }
}