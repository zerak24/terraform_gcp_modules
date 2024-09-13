variable "project" {
  type = object({
    project_id = string
    region     = string
    env        = string
    company    = string
  })
}
variable "vpc" {
  type = object({
    subnets = optional(list(object({
      subnet_name = optional(string)
      subnet_ip   = optional(string)
      nat_enabled = optional(bool, false)
      secondary_ranges = optional(list(object({
        range_name    = optional(string)
        ip_cidr_range = optional(string)
      })))
    })))
    routes = optional(list(any), [])
    egress_rules = optional(list(object({
      name          = optional(string)
      source_ranges = optional(list(string))
      allow = optional(list(object({
        protocol = optional(string)
        ports    = optional(list(string))
      })))
    })), [])
    ingress_rules = optional(list(object({
      name          = optional(string)
      source_ranges = optional(list(string))
      target_tags   = optional(list(string))
      allow = optional(list(object({
        protocol = optional(string)
        ports    = optional(list(string))
      })))
    })), [])
  })
  default = null
}
