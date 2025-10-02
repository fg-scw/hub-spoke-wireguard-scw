# Génération des clés Wireguard
resource "wireguard_asymmetric_key" "wg_hub" {}
resource "wireguard_asymmetric_key" "wg_spoke_01" {}
resource "wireguard_asymmetric_key" "wg_spoke_02" {}

locals {
  # Clés Wireguard
  wg_keys = {
    hub = {
      private = wireguard_asymmetric_key.wg_hub.private_key
      public  = wireguard_asymmetric_key.wg_hub.public_key
    }
    spoke_01 = {
      private = wireguard_asymmetric_key.wg_spoke_01.private_key
      public  = wireguard_asymmetric_key.wg_spoke_01.public_key
    }
    spoke_02 = {
      private = wireguard_asymmetric_key.wg_spoke_02.private_key
      public  = wireguard_asymmetric_key.wg_spoke_02.public_key
    }
  }

  # IPs Wireguard internes
  wg_ips = {
    hub      = "192.168.1.1"
    spoke_01 = "192.168.1.2"
    spoke_02 = "192.168.1.3"
  }

  # Configuration des VPCs et réseaux
  vpcs = {
    hub = {
      name   = "WG - VPC HUB"
      subnet = "172.16.188.0/22"
      tags   = ["hub", "wireguard", "vpn"]
    }
    spoke_01 = {
      name   = "WG - VPC SPOKE01"
      subnet = "172.16.32.0/22"
      tags   = ["spoke01", "wireguard", "vpn"]
    }
    spoke_02 = {
      name   = "WG - VPC SPOKE02"
      subnets = {
        a = "172.16.64.0/23"
        b = "172.16.66.0/23"
      }
      tags = ["spoke02", "wireguard", "vpn"]
    }
  }

  # Configuration des instances Wireguard
  wg_instances = {
    hub = {
      name = "wireguard-hub"
      type = "PLAY2-MICRO"
      peers = [
        {
          public_key   = local.wg_keys.spoke_01.public
          # Hub accepte le trafic du spoke_01 et de son réseau
          allowed_ips  = "${local.wg_ips.spoke_01}/32,${local.vpcs.spoke_01.subnet}"
          endpoint_ref = "spoke_01"
        },
        {
          public_key   = local.wg_keys.spoke_02.public
          # Hub accepte le trafic du spoke_02 et de ses réseaux
          allowed_ips  = "${local.wg_ips.spoke_02}/32,${local.vpcs.spoke_02.subnets.a},${local.vpcs.spoke_02.subnets.b}"
          endpoint_ref = "spoke_02"
        }
      ]
    }
    spoke_01 = {
      name = "wireguard-spoke-01"
      type = "PLAY2-MICRO"
      peers = [
        {
          public_key   = local.wg_keys.hub.public
          # Spoke01 route tout vers le hub (y compris Internet)
          allowed_ips  = "0.0.0.0/0"
          endpoint_ref = "hub"
        }
      ]
    }
    spoke_02 = {
      name = "wireguard-spoke-02"
      type = "PLAY2-MICRO"
      peers = [
        {
          public_key   = local.wg_keys.hub.public
          # Spoke02 route TOUT vers le hub (y compris Internet)
          allowed_ips  = "0.0.0.0/0"
          endpoint_ref = "hub"
        }
      ]
    }
  }
}