variable "project" {
  type = object({
    project_id = string
    region     = string
    env        = string
    company    = string
  })
}
variable "cdn" {
  type = object({
    name = string
    enable_ipv6 = optional(bool, false)
    custom_request_headers = optional(list(string))
    custom_response_headers = optional(list(string))
    timeout_sec = optional(number, 60)
    log_enable = optional(bool, false)
    cdn_config = optional(object({
      cache_mode        = optional(string, "CACHE_ALL_STATIC")
      client_ttl        = optional(number, 300)
      default_ttl       = optional(number, 3600)
      max_ttl           = optional(number, 86400)
    }))
  })
  default = null
}
variable "bucket" {
  type = object({
    name = string
    cors = optional(set(map(any)))
    versioning = optional(bool, false)
  })
  default = null
}