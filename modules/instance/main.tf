data "openstack_images_image_v2" "image" {
  name        = var.image_name
  most_recent = true
}

resource "openstack_compute_servergroup_v2" "servergroup" {
  name     = "${var.name}-servergroup"
  policies = [var.affinity]
}

resource "openstack_blockstorage_volume_v2" "volume" {
  count = var.nodes_count
  name  = "${openstack_compute_instance_v2.instance[count.index].name}-rke2"
  size  = var.rke2_volume_size
}

resource "openstack_compute_volume_attach_v2" "attach" {
  count       = var.nodes_count
  instance_id = openstack_compute_instance_v2.instance[count.index].id
  volume_id   = openstack_blockstorage_volume_v2.volume[count.index].id
}

resource "openstack_networking_floatingip_v2" "floating_ip" {
  count = var.floating_pool != "" ? var.nodes_count : 0
  pool  = var.floating_pool

  lifecycle {
    prevent_destroy = false
  }
}

resource "openstack_compute_floatingip_associate_v2" "associate_floating_ip" {
  count       = var.floating_pool != "" ? var.nodes_count : 0
  floating_ip = openstack_networking_floatingip_v2.floating_ip[count.index].address
  instance_id = openstack_compute_instance_v2.instance[count.index].id
}

resource "openstack_networking_port_v2" "port" {
  count = var.nodes_count

  network_id         = var.network_id
  security_group_ids = var.secgroup_id != null ? [var.secgroup_id] : null
  no_security_groups = var.secgroup_id == null
  admin_state_up     = true

  fixed_ip {
    subnet_id  = var.subnet_id
    ip_address = var.is_server && var.is_bootstrap && count.index == 0 ? var.bootstrap_server : null
  }

  dynamic "fixed_ip" {
    for_each = var.subnet_ext_id != "" ? [1] : []
    content {
      subnet_id = var.subnet_ext_id
    }
  }
}

locals {
  external_ips = var.is_server ? openstack_networking_port_v2.port[*].fixed_ip[0].ip_address : []
  floating_ips = var.floating_pool != "" ? openstack_networking_floatingip_v2.floating_ip[*].address : []
}

resource "openstack_compute_instance_v2" "instance" {
  count                   = var.nodes_count
  name                    = var.nodes_count == 1 ? var.name : "${var.name}-${count.index + 1}"
  availability_zone_hints = length(var.availability_zones) > 0 ? var.availability_zones[count.index % length(var.availability_zones)] : null

  flavor_name  = var.flavor_name
  key_pair     = var.keypair_name
  config_drive = true

  network {
    port = openstack_networking_port_v2.port[count.index].id
  }

  scheduler_hints {
    group = openstack_compute_servergroup_v2.servergroup.id
  }

  metadata = {
    rke2_version = var.rke2_version
    rke2_role    = var.is_server ? "server" : "agent"
  }

  block_device {
    uuid                  = var.image_uuid != null ? var.image_uuid : data.openstack_images_image_v2.image.id
    source_type           = "image"
    volume_size           = var.boot_volume_size
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/cloud-init.yml.tpl", {
    rke2_token   = var.rke2_token
    rke2_version = var.rke2_version
    # https://docs.rke2.io/install/install_options/server_config/
    rke2_conf        = var.rke2_config != null ? var.rke2_config : ""
    is_server        = var.is_server
    bootstrap_server = var.is_server && var.is_bootstrap && count.index == 0 ? "" : var.bootstrap_server
    san              = var.is_server ? concat(local.external_ips, local.floating_ips) : []
    manifests_files = var.is_server ? merge(
      var.manifests_folder != "" ? {
        for f in fileset(var.manifests_folder, "*.{yml,yaml}") : f => base64gzip(file("${var.manifests_folder}/${f}"))
      } : {},
      { for k, v in var.manifests : k => base64gzip(v) },
    ) : {}
    s3_endpoint      = var.s3.endpoint
    s3_access_key    = var.s3.access_key
    s3_access_secret = var.s3.access_secret
    s3_bucket        = var.s3.bucket
  }))
}
