locals {
  secondary_ranges = { for sub in var.vpc.subnets : sub.subnet_name => sub.secondary_ranges }
}
module "vpc" {
  count = var.vpc == null ? 0 : 1
  source = "git::https://github.com/terraform-google-modules/terraform-google-network.git?ref=v9.2.0"

  project_id   = var.project.project_id
  network_name = format("%s-%s-vpc", var.project.company, var.project.env)
  routing_mode = "GLOBAL"

  subnets = [for sub in var.vpc.subnets :
    {
      subnet_name           = format("%s-%s", var.project.env, sub.subnet_name)
      subnet_ip             = sub.subnet_ip
      subnet_region         = var.project.region
  }]

  secondary_ranges = { for sub in var.vpc.subnets : format("%s-%s", var.project.env, sub.subnet_name) => sub.secondary_ranges if sub.secondary_ranges != null }

  routes = var.vpc.routes

  ingress_rules = var.vpc.ingress_rules

  egress_rules = var.vpc.egress_rules
}

module "nat" {
  for_each = toset([ for sub in var.vpc.subnets : sub.subnet_name if sub.nat_enabled ])
  source        = "git::https://github.com/terraform-google-modules/terraform-google-cloud-nat.git?ref=v5.3.0"

  project_id    = var.project.project_id
  region        = var.project.region
  name          = format("%v-%v", var.project.env, each.key)
  create_router = true
  router        = format("%v-%v-router", var.project.env, each.key)
  network       = module.vpc[0].network_name
}

module "postgresql" {
  for_each = { for k, v in var.db : k => v if v.type == "postgresql" }
  source = "git::git@github.com:terraform-google-modules/terraform-google-sql-db.git//modules/postgresql?ref=v21.0.2"

  project_id                  = var.project.project_id
  region                      = var.project.region
  name                        = each.key
  database_version            = each.value.database_version
  tier                        = each.value.tier
  zone                        = each.value.zone
  availability_type           = each.value.availability_type
  deletion_protection_enabled = each.value.deletion_protection_enabled
  database_flags              = each.value.database_flags
  read_replica_name_suffix    = each.value.read_replica_name_suffix
  read_replicas               = each.value.read_replicas
  disk_size                   = each.value.disk_size
  disk_type                   = each.value.disk_type
  disk_autoresize             = each.value.disk_autoresize
  disk_autoresize_limit       = each.value.disk_autoresize_limit
  ip_configuration = {
    ipv4_enabled = false
    # ssl_mode = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
    private_network = format("https://www.googleapis.com/compute/v1/projects/%v/global/networks/%v", var.project.project_id, module.vpc[0].network_name)
    #   allocated_ip_range = "default-sql"
  }
  backup_configuration = {
    enabled                        = true
    start_time                     = "3:00"
    point_in_time_recovery_enabled = false
  }
}

module "mysql" {
  for_each = { for k, v in var.db : k => v if v.type == "mysql" }
  source = "git::git@github.com:terraform-google-modules/terraform-google-sql-db.git//modules/mysql?ref=v21.0.2"

  project_id                  = var.project.project_id
  region                      = var.project.region
  name                        = each.key
  database_version            = each.value.database_version
  tier                        = each.value.tier
  zone                        = each.value.zone
  availability_type           = each.value.availability_type
  deletion_protection_enabled = each.value.deletion_protection_enabled
  database_flags              = each.value.database_flags
  read_replica_name_suffix    = each.value.read_replica_name_suffix
  read_replicas               = each.value.read_replicas
  disk_size                   = each.value.disk_size
  disk_type                   = each.value.disk_type
  disk_autoresize             = each.value.disk_autoresize
  disk_autoresize_limit       = each.value.disk_autoresize_limit
  ip_configuration = {
    ipv4_enabled = false
    # ssl_mode = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
    private_network = format("https://www.googleapis.com/compute/v1/projects/%v/global/networks/%v", var.project.project_id, module.vpc[0].network_name)
    #   allocated_ip_range = "default-sql"
  }
  backup_configuration = {
    enabled                        = true
    start_time                     = "3:00"
    point_in_time_recovery_enabled = false
  }
}
