module "cdn" {
  count = var.cdn == null ? 0 : 1
  source     = "git::https://github.com/terraform-google-modules/terraform-google-lb-http.git?ref=v12.0.0"
  project = var.project.project_id
  name       = var.cdn.name
  backends = {
    default = {
      custom_request_headers          = var.cdn.custom_request_headers
      custom_response_headers         = var.cdn.custom_response_headers
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = var.cdn.timeout_sec
      enable_cdn                      = true
      groups = [
        {
          group                        = "default"
        },
      ]
      log_config = {
        enable = var.cdn.log_enable
        sample_rate = 1.0
      }
      iap_config = {
        enable               = false
      }
    }
  }
  url_map = google_compute_url_map.default.self_link
  enable_ipv6 = var.cdn.enable_ipv6
  create_ipv6_address = var.cdn.enable_ipv6
  ssl = true
  create_ssl_certificate = true
  create_address = true
}

resource "google_compute_backend_bucket" "default" {
  count = var.cdn == null || var.bucket == null ? 0 : 1
  name        = var.bucket.name
  bucket_name = module.bucket[0].names["${var.bucket.name}"]
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
  count = var.bucket == null ? 0 : 1
  name       = var.cdn.name
  default_service = google_compute_backend_bucket.default.id
}

module "bucket" {
  count = var.bucket == null ? 0 : 1
  source = "git::https://github.com/terraform-google-modules/terraform-google-cloud-storage.git?ref=v6.1.0"

  project_id = var.project.project_id
  location = var.project.region

  names = [var.bucket.name]

  website = {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  viewers = ["allUsers"]
  cors = toset([ for obj in var.bucket.cors: {
    origin = obj.origin
    method = obj.method
    response_header = obj.response_header
    max_age_seconds = obj.max_age_seconds
  }])
  versioning = {
    "${var.bucket.name}" = var.bucket.versioning
  }
}