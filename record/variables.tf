variable "project" {
  type = object({
    project_id = string
    region     = string
    env        = string
    company    = string
  })
}
variable "cloud_dns" {
  type = map(object({
    recordsets = optional(list(object({
      name    = optional(string)
      type    = optional(string)
      ttl     = optional(number, 300)
      records = optional(list(string))
    })))
  }))
  default = {}
}