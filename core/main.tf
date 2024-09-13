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
  for_each = { for sub in var.vpc.subnets : sub.subnet_name => {} if sub.nat_enabled }
  source        = "git::https://github.com/terraform-google-modules/terraform-google-cloud-nat.git?ref=v5.3.0"

  project_id    = var.project.project_id
  region        = var.project.region
  name          = format("%v-%v", var.project.env, each.key)
  create_router = true
  router        = format("%v-%v-router", var.project.env, each.key)
  network       = module.vpc[0].network_name
}