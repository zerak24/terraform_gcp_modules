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
    })))
    secondary_ranges = optional(map(list(object({
      range_name    = optional(string)
      ip_cidr_range = optional(string)
    }))))
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

variable "nat" {
  type = map(object({
    name = optional(string)
    subnets = optional(list(object({
      name                     = optional(string)
      source_ip_ranges_to_nat  = optional(list(string))
      secondary_ip_range_names = optional(list(string))
    })))
    create_router = optional(bool, true)
  }))
  default = {}
}