
variable "name" {
  type = string
}

variable "ssh_public_key_file" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "floating_pool" {
  type    = string
  default = ""
}

variable "rules_ext" {
  type = list(object({
    port     = number
    protocol = string
    source   = string
    name     = optional(string)
  }))
}

variable "subnet_servers_cidr" {
  type    = string
  default = "192.168.42.0/24"
}

variable "bootstrap_server" {
  type    = string
  default = "192.168.42.3"
}

variable "subnet_agents_cidr" {
  type    = string
  default = "192.168.43.0/24"
}

variable "dns_nameservers4" {
  type = list(string)
  # Cloudflare
  default = ["1.1.1.1", "1.0.0.1"]
}

variable "dns_nameservers6" {
  type = list(string)
  # Cloudflare
  default = ["2606:4700:4700::1111", "2606:4700:4700::1001"]
}

variable "servers" {
  type = list(object({
    name               = string
    affinity           = optional(string)
    availability_zones = optional(list(string))
    flavor_name        = string
    image_name         = string
    image_uuid         = optional(string)
    system_user        = string
    boot_volume_size   = number
    rke2_version       = string
    rke2_config        = optional(string)
    rke2_volume_size   = number
  }))
}

variable "agents" {
  type = list(object({
    name               = string
    nodes_count        = number
    affinity           = optional(string)
    availability_zones = optional(list(string))
    flavor_name        = string
    image_name         = string
    image_uuid         = optional(string)
    system_user        = string
    boot_volume_size   = number
    rke2_version       = string
    rke2_config        = optional(string)
    rke2_volume_size   = number
  }))
}

variable "s3_backup" {
  type = object({
    endpoint      = string
    access_key    = string
    access_secret = string
    bucket        = string
  })
  default = {
    endpoint      = ""
    access_key    = ""
    access_secret = ""
    bucket        = ""
  }
}

variable "manifests_folder" {
  type    = string
  default = ""
}

variable "manifests" {
  type    = map(string)
  default = {}
}

variable "ff_native_csi" {
  type    = string
  default = ""
}

variable "ff_write_kubeconfig" {
  type    = bool
  default = true
}

variable "ff_autoremove_agent" {
  type    = bool
  default = true
}

variable "ff_native_backup" {
  type    = string
  default = ""
}

variable "ff_snapshot_controller" {
  type    = bool
  default = true
}
