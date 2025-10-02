variable "zone" {
  description = "Scaleway zone"
  type        = string
  default     = "fr-par-1"
}

variable "region" {
  description = "Scaleway region"
  type        = string
  default     = "fr-par"
}

variable "wireguard_port" {
  description = "Port Wireguard"
  type        = number
  default     = 52345
}

variable "wireguard_mtu" {
  description = "MTU Wireguard"
  type        = number
  default     = 1380
}

variable "ssh_public_key" {
  description = "Clé publique SSH pour accès aux instances"
  type        = string
  validation {
    condition     = length(var.ssh_public_key) > 0
    error_message = "La clé SSH publique est obligatoire."
  }
}