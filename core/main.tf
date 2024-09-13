module "vpc" {
  count = var.vpc == null ? 0 : 1
  source = "git::https://github.com/terraform-google-modules/terraform-google-network.git?ref=v9.2.0"

  # project_id   = var.project.project_id
  network_name = format("%s-%s-vpc", var.project.company, var.project.env)
  routing_mode = "GLOBAL"

  subnets = [for sub in var.vpc.subnets :
    {
      subnet_name           = format("%v-%v", var.project.env, sub.subnet_name)
      subnet_ip             = sub.subnet_ip
      subnet_region         = var.project.region
      subnet_private_access = false
  }]

  secondary_ranges = merge([for key, value in var.vpc.secondary_ranges :
    {
      format(format("%v-%v", var.project.env, key)) = value
    }
  ]...)

  routes = var.vpc.routes

  ingress_rules = var.vpc.ingress_rules

  egress_rules = var.vpc.egress_rules
}

module "nat" {
  for_each = var.nat
  source        = "git::https://github.com/terraform-google-modules/terraform-google-cloud-nat.git?ref=v5.3.0"

  # project_id    = var.project.project_id
  # region        = var.project.region
  name          = format("%v-%v", var.project.env, each.value.name)
  create_router = each.value.create_router
  router        = format("%v-%v-router", var.project.env, each.value.name)
  network       = module.vpc[0].network_name
  subnetworks = [for sub in each.value.subnets :
    {
      name                     = format("%v-%v", var.project.env, each.value.name)
      source_ip_ranges_to_nat  = sub.source_ip_ranges_to_nat
      secondary_ip_range_names = sub.secondary_ip_range_names
    }
  ]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
}