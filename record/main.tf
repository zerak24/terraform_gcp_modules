module "dns" {
  count = var.cloud_dns == null : 0 ? 1
  source                             = "git::https://github.com/terraform-google-modules/terraform-google-cloud-dns.git?ref=v5.3.0"
  
  project_id                         = var.project.project_id
  type                               = "public"
  name                               = var.cloud_dns.name
  domain                             = var.cloud_dns.domain
  recordsets                         = var.cloud_dns.recordsets
}