module "dns" {
  for_each = var.cloud_dns
  source   = "git::https://github.com/terraform-google-modules/terraform-google-cloud-dns.git?ref=v5.3.0"

  project_id = var.project.project_id
  type       = "public"
  name       = each.key
  domain     = each.key
  recordsets = each.value.recordsets
}

resource "google_compute_managed_ssl_certificate" "certs" {
  for_each = var.cloud_dns
  project  = var.project.project_id
  name     = each.key
  managed {
    domains = ["${each.key}", format("*.%s", each.key)]
  }
}