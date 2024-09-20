resource "google_storage_bucket" "default" {
  count                       = var.bucket == null ? 0 : 1
  project                     = var.project.project_id
  name                        = format("%s-%s-%s-bucket", var.project.company, var.project.env, var.bucket.name)
  location                    = var.project.region
  uniform_bucket_level_access = true
  storage_class               = "STANDARD"
  force_destroy               = false
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  dynamic "cors" {
    for_each = var.bucket.cors
    content {
      origin          = cors.value.origin
      method          = cors.value.method
      response_header = cors.value.response_header
      max_age_seconds = cors.value.max_age_seconds
    }
  }
  versioning {
    enabled = var.bucket.versioning
  }
}

resource "google_storage_bucket_iam_member" "default" {
  count  = var.bucket == null ? 0 : 1
  bucket = google_storage_bucket.default[0].name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_compute_global_address" "default" {
  count   = var.cdn == null ? 0 : 1
  project = var.project.project_id
  name    = format("%s-%s-%s-ip", var.project.company, var.project.env, var.bucket.name)
}

resource "google_compute_backend_bucket" "default" {
  count       = var.bucket == null ? 0 : 1
  project     = var.project.project_id
  name        = format("%s-%s-%s-backend-bucket", var.project.company, var.project.env, var.bucket.name)
  bucket_name = google_storage_bucket.default[0].name
  enable_cdn  = true
  cdn_policy {
    cache_mode        = var.cdn.cdn_config.cache_mode
    client_ttl        = var.cdn.cdn_config.client_ttl
    default_ttl       = var.cdn.cdn_config.default_ttl
    max_ttl           = var.cdn.cdn_config.max_ttl
    negative_caching  = true
    serve_while_stale = 86400
  }
}

resource "google_compute_url_map" "default" {
  count           = var.cdn == null ? 0 : 1
  project         = var.project.project_id
  name            = format("%s-%s-%s-url-map", var.project.company, var.project.env, var.bucket.name)
  default_service = google_compute_backend_bucket.default[0].id
}

resource "google_compute_managed_ssl_certificate" "default" {
  count   = var.cdn == null ? 0 : 1
  project = var.project.project_id
  name    = format("%s-%s-%s-ssl-cert", var.project.company, var.project.env, var.bucket.name)
  managed {
    domains = var.cdn.managed_ssl_certificate_domains
  }
}

resource "google_compute_target_https_proxy" "default" {
  count            = var.cdn == null ? 0 : 1
  project          = var.project.project_id
  name             = format("%s-%s-%s-proxy", var.project.company, var.project.env, var.bucket.name)
  url_map          = google_compute_url_map.default[0].id
  ssl_certificates = [google_compute_managed_ssl_certificate.default[0].id]
}

resource "google_compute_global_forwarding_rule" "default" {
  count                 = var.cdn == null ? 0 : 1
  project               = var.project.project_id
  name                  = format("%s-%s-%s-fw-rule", var.project.company, var.project.env, var.bucket.name)
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_https_proxy.default[0].id
  ip_address            = google_compute_global_address.default[0].id
}
