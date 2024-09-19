# module "cdn" {
#   count = var.cdn == null ? 0 : 1
#   source     = "git::https://github.com/terraform-google-modules/terraform-google-lb-http.git?ref=v12.0.0"
#   project = var.project.project_id
#   name       = var.cdn.name
#   backends = {
#     default = {
#       custom_request_headers          = var.cdn.custom_request_headers
#       custom_response_headers         = var.cdn.custom_response_headers
#       protocol                        = "HTTP"
#       port                            = 80
#       port_name                       = "http"
#       timeout_sec                     = var.cdn.timeout_sec
#       enable_cdn                      = true
#       groups = [
#         {
#           group                        = "default"
#         },
#       ]
#       log_config = {
#         enable = var.cdn.log_enable
#         sample_rate = 1.0
#       }
#       iap_config = {
#         enable               = false
#       }
#     }
#   }
#   url_map = google_compute_url_map.default[0].self_link
#   enable_ipv6 = var.cdn.enable_ipv6
#   create_ipv6_address = var.cdn.enable_ipv6
#   ssl = true
#   managed_ssl_certificate_domains = var.cdn.managed_ssl_certificate_domains
#   create_address = true
# }

# resource "google_compute_backend_bucket" "default" {
#   count = var.cdn == null || var.bucket == null ? 0 : 1
#   name        = var.bucket.name
#   project = var.project.project_id
#   bucket_name = module.bucket[0].names["${var.bucket.name}"]
#   enable_cdn  = true
#   cdn_policy {
#     cache_mode        = var.cdn.cdn_config.cache_mode
#     client_ttl        = var.cdn.cdn_config.client_ttl
#     default_ttl       = var.cdn.cdn_config.default_ttl
#     max_ttl           = var.cdn.cdn_config.max_ttl
#     negative_caching  = true
#     serve_while_stale = 86400
#   }
# }

# resource "google_compute_url_map" "default" {
#   count = var.bucket == null ? 0 : 1
#   project = var.project.project_id
#   name       = var.cdn.name
#   default_service = google_compute_backend_bucket.default[0].id
# }

# module "bucket" {
#   count = var.bucket == null ? 0 : 1
#   source = "git::https://github.com/terraform-google-modules/terraform-google-cloud-storage.git?ref=v6.1.0"

#   project_id = var.project.project_id
#   location = var.project.region

#   names = [var.bucket.name]

#   website = {
#     main_page_suffix = "index.html"
#     not_found_page   = "404.html"
#   }
#   viewers = ["allUsers"]
#   cors = toset([ for obj in var.bucket.cors: {
#     origin = obj.origin
#     method = obj.method
#     response_header = obj.response_header
#     max_age_seconds = obj.max_age_seconds
#   }])
#   versioning = {
#     "${var.bucket.name}" = var.bucket.versioning
#   }
# }




resource "google_storage_bucket" "default" {
  count = var.bucket == null ? 0 : 1
  project = var.project.project_id
  name                        = var.bucket.name
  location                    = var.project.region
  uniform_bucket_level_access = true
  storage_class               = "STANDARD"
  force_destroy = false
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  dynamic "cors" {
    for_each = var.bucket.cors
    content {
      origin = cors.value.origin
      method = cors.value.method
      response_header = cors.value.response_header
      max_age_seconds = cors.value.max_age_seconds
    }
  }
  versioning {
    enabled = var.bucket.versioning
  }
}

resource "google_storage_bucket_iam_member" "default" {
  count = var.bucket == null ? 0 : 1
  bucket = google_storage_bucket.default[0].name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_compute_global_address" "default" {
  count = var.cdn == null ? 0 : 1
  project = var.project.project_id
  name = var.cdn.name
}

resource "google_compute_backend_bucket" "default" {
  count = var.bucket == null ? 0 : 1
  project = var.project.project_id
  name        = var.bucket.name
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
  count = var.cdn == null ? 0 : 1
  project = var.project.project_id
  name = var.cdn.name
  default_service = google_compute_backend_bucket.default[0].id
}

resource "google_compute_managed_ssl_certificate" "default" {
  count = var.cdn == null ? 0 : 1
  project = var.project.project_id
  name = var.cdn.name
  managed {
    domains = var.cdn.managed_ssl_certificate_domains
  }
}

resource "google_compute_target_https_proxy" "default" {
  count = var.cdn == null ? 0 : 1
  project = var.project.project_id
  name = var.cdn.name
  url_map = google_compute_url_map.default[0].id
  ssl_certificates = [google_compute_managed_ssl_certificate.default[0].id]
}

resource "google_compute_global_forwarding_rule" "default" {
  count = var.cdn == null ? 0 : 1
  project = var.project.project_id
  name = var.cdn.name
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_https_proxy.default[0].id
  ip_address            = google_compute_global_address.default[0].id
}
