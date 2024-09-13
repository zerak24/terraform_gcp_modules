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

variable "db" {
  type = map(object({
      type                        = optional(string)
      name                        = optional(string)
      database_version            = optional(string)
      tier                        = optional(string)
      zone                        = optional(string)
      availability_type           = optional(string)
      deletion_protection_enabled = optional(bool, true)
      database_flags              = optional(list(any), [])
      read_replica_name_suffix    = optional(string)
      read_replicas               = optional(list(any), [])
      disk_size                   = optional(number)
      disk_type                   = optional(string)
      disk_autoresize             = optional(bool, true)
      disk_autoresize_limit       = optional(number, 0)
  }))
  default = {}
}