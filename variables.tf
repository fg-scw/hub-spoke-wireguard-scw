variable "zone" {
  type    = string
  default = "fr-par-1"
}

variable "region" {
  type    = string
  default = "fr-par"
}

# Credentials Scaleway
variable "scaleway_access_key" {
  type      = string
  sensitive = true
}
variable "scaleway_secret_key" {
  type      = string
  sensitive = true
}
variable "scaleway_project_id" {
  type = string
}

# WireGuard (noms "officiels")
variable "wg_port" {
  type    = number
  default = 51820
}
variable "wg_mtu" {
  type    = number
  default = 1380
}

# Aliases pour compat tfvars existant (wireguard_port / wireguard_mtu)
variable "wireguard_port" {
  type    = number
  default = null
}
variable "wireguard_mtu" {
  type    = number
  default = null
}

variable "wg_instance_type" {
  type    = string
  default = "PLAY2-MICRO"
}
variable "client_instance_type" {
  type    = string
  default = "DEV1-S"
}

variable "image" {
  description = "Image pour les instances (ex: ubuntu_jammy)"
  type        = string
  default     = "ubuntu_jammy"
}

variable "ssh_public_key" {
  type = string
}

# DB
variable "db_name" {
  type    = string
  default = "appdb"
}
variable "db_user" {
  type    = string
  default = "dbadmin"
}
variable "db_password" {
  type      = string
  sensitive = true
}

# IP privée du SPOKE02 (passerelle client)
variable "spoke02_lan_ip" {
  type = string
}
