locals {
  # Valeurs effectives (compat tfvars existant)
  effective_wg_port = coalesce(var.wireguard_port, var.wg_port)
  effective_wg_mtu  = coalesce(var.wireguard_mtu, var.wg_mtu)

  # /24 du réseau WireGuard
  wg_network_cidr = "192.168.1.0/24"

  # IPs WG
  wg_ips = {
    hub     = "192.168.1.1"
    spoke01 = "192.168.1.11"
    spoke02 = "192.168.1.12"
  }

  # Subnets VPC
  vpcs = {
    hub = {
      subnet = "172.16.10.0/23"
    }
    spoke_01 = {
      subnet = "172.16.32.0/23"
    }
    spoke_02 = {
      subnets = {
        a = "172.16.64.0/23"
        b = "172.16.66.0/23"
      }
    }
  }

  # Inventaire WG (clé publique = ressources ci-dessus)
  wg_instances = {
    hub = {
      name = "wireguard-hub"
      type = var.wg_instance_type
      peers = [
        {
          public_key   = wireguard_asymmetric_key.spoke01.public_key
          allowed_ips  = "192.168.1.11/32, ${local.vpcs.spoke_01.subnet}"
          endpoint_ref = "spoke01"
        },
        {
          public_key   = wireguard_asymmetric_key.spoke02.public_key
          allowed_ips  = "192.168.1.12/32, ${local.vpcs.spoke_02.subnets.a}, ${local.vpcs.spoke_02.subnets.b}"
          endpoint_ref = "spoke02"
        }
      ]
    }
    spoke01 = {
      name          = "wireguard-spoke-01"
      type          = var.wg_instance_type
      local_subnets = [local.vpcs.spoke_01.subnet]
    }
    spoke02 = {
      name          = "wireguard-spoke-02"
      type          = var.wg_instance_type
      local_subnets = [local.vpcs.spoke_02.subnets.a, local.vpcs.spoke_02.subnets.b]
    }
  }
}
