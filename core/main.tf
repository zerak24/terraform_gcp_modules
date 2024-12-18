module "vpc" {
  count  = var.vpc == null ? 0 : 1
  source = "git::https://github.com/terraform-google-modules/terraform-google-network.git?ref=v9.2.0"

  project_id   = var.project.project_id
  network_name = format("%s-%s-vpc", var.project.company, var.project.env)
  routing_mode = "GLOBAL"

  subnets = [for sub in var.vpc.subnets :
    {
      subnet_name   = format("%s-%s", var.project.env, sub.subnet_name)
      subnet_ip     = sub.subnet_ip
      subnet_region = var.project.region
  }]

  secondary_ranges = { for sub in var.vpc.subnets : format("%s-%s", var.project.env, sub.subnet_name) => sub.secondary_ranges if sub.secondary_ranges != null }

  routes = var.vpc.routes

  ingress_rules = var.vpc.ingress_rules

  egress_rules = var.vpc.egress_rules
}

module "nat" {
  for_each = toset([for sub in var.vpc.subnets : sub.subnet_name if sub.nat_enabled])
  source   = "git::https://github.com/terraform-google-modules/terraform-google-cloud-nat.git?ref=v5.3.0"

  project_id    = var.project.project_id
  region        = var.project.region
  name          = format("%v-%v", var.project.env, each.key)
  create_router = true
  router        = format("%v-%v-router", var.project.env, each.key)
  network       = module.vpc[0].network_name
}

module "postgresql" {
  for_each = { for k, v in var.db : k => v if v.type == "postgresql" }
  source   = "git::git@github.com:terraform-google-modules/terraform-google-sql-db.git//modules/postgresql?ref=v21.0.2"

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
    ipv4_enabled    = false
    private_network = module.vpc[0].network_self_link
  }
  backup_configuration = {
    enabled                        = true
    start_time                     = "3:00"
    point_in_time_recovery_enabled = false
  }
}

module "mysql" {
  for_each = { for k, v in var.db : k => v if v.type == "mysql" }
  source   = "git::git@github.com:terraform-google-modules/terraform-google-sql-db.git//modules/mysql?ref=v21.0.2"

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
    ipv4_enabled    = false
    private_network = module.vpc[0].network_self_link
  }
  backup_configuration = {
    enabled                        = true
    start_time                     = "3:00"
    point_in_time_recovery_enabled = false
  }
}

resource "google_compute_address" "ip_address" {
  for_each = var.ce

  project      = var.project.project_id
  region       = var.project.region
  name         = format("%s-%s-%s-external-ip", var.project.company, var.project.env, each.key)
  address_type = "EXTERNAL"
  network_tier = "STANDARD"
}

module "template" {
  for_each = var.ce
  source   = "git::https://github.com/terraform-google-modules/terraform-google-vm.git//modules/instance_template?ref=v12.0.0"

  project_id = var.project.project_id
  region     = var.project.region
  # network              = module.vpc[0].network_self_link
  # subnetwork           = module.vpc[0].subnets_self_links[index(var.vpc[0].subnets_names, "${each.value.subnetwork_name}")]
  disk_size_gb         = each.value.disk_size_gb
  disk_type            = each.value.disk_type
  machine_type         = each.value.machine_type
  source_image         = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"
  name_prefix          = format("%s-%s-%s", var.project.company, var.project.env, each.key)
  service_account = {
    email  = "default"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  tags = each.value.tags
}

module "compute" {
  for_each            = var.ce
  source              = "git::https://github.com/terraform-google-modules/terraform-google-vm.git//modules/compute_instance?ref=v12.0.0"
  subnetwork_project  = var.project.project_id
  region              = var.project.region
  network             = module.vpc[0].network_self_link
  subnetwork          = module.vpc[0].subnets_self_links[index(var.vpc[0].subnets_names, "${each.value.subnetwork_name}")]
  hostname            = format("%s-%s-%s-compute-engine", var.project.company, var.project.env, each.key)
  add_hostname_suffix = false
  instance_template   = module.template["${each.key}"].self_link_unique
  num_instances       = "1"
  access_config = [{
    nat_ip       = google_compute_address.ip_address["${each.key}"].address
    network_tier = "STANDARD"
  }]
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  count  = var.gke == null ? 0 : 1
  source = "git::https://github.com/terraform-google-modules/terraform-google-kubernetes-engine.git?ref=v33.0.1"

  project_id                 = var.project.project_id
  name                       = format("%s-%s-eks", var.project.company, var.project.env)
  region                     = var.project.region
  zones                      = var.gke.zones
  network                    = var.project.env
  subnetwork                 = var.gke.subnet
  ip_range_pods              = var.gke.pod_cidr
  ip_range_services          = var.gke.svc_cidr
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = true
  create_service_account     = true
  service_account_name       = "cli-service-account-1@playground-s-11-ea852893.iam.gserviceaccount.com"
  remove_default_node_pool   = true
  deletion_protection        = false
  release_channel            = "STABLE"

  cluster_autoscaling = {}

  node_pools = [for k, v in var.gke.node_pools :
    {
      name                        = each.key
      machine_type                = each.machine_type
      node_locations              = var.gke.zones[idx]
      min_count                   = each.min_nodes
      max_count                   = each.max_nodes
      local_ssd_count             = 0
      spot                        = each.spot_plan
      disk_size_gb                = 50
      disk_type                   = "pd-standard"
      image_type                  = "COS_CONTAINERD"
      enable_gcfs                 = false
      enable_gvnic                = false
      logging_variant             = "DEFAULT"
      auto_repair                 = true
      auto_upgrade                = true
      service_account_name        = "${each.key}-gke-service-account"
      preemptible                 = false
      enable_integrity_monitoring = false
    }
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}