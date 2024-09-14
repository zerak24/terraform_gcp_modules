variable "project" {
  type = object({
    project_id = string
    region     = string
    env        = string
    company    = string
  })
}
variable "inputs" {
  type = map(object({
    cdn_domain = string
  }))
  default = {}
}