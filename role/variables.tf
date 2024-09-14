variable "project" {
  type = object({
    project_id = string
    region     = string
    env        = string
    company    = string
  })
}
variable "role" {
  type = object({
    name      = optional(string)
    namespace = optional(string)
    roles     = optional(list(string))
  })
  default = null
}
