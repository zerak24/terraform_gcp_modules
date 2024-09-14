module "cdn-web" {
  count = var.cdn-web == null : 0 ? 1
  source     = "git@github.com:zerak24/terraform_modules.git//gcp/lb"
  project_id = var.project.project_id
  region     = var.project.region
  name       = each.key
  cdn_domain = each.value.cdn_domain

}
