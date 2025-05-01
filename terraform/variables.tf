variable "context" {
  type = any
  default = {
    enabled     = true
    environment = null
    name        = null
    delimiter   = null
    tags        = {}
    attributes  = []
    label_order = []
  }
  description = <<-EOT
    Single object for setting entire context at once.
    See description of individual variables for details.
  EOT

}

variable "enabled" {
  type        = bool
  default     = null
  description = "Set to false to prevent the module from creating any resources"
}

variable "environment" {
  type        = string
  description = "Environment, e.g. 'us-west-2', OR 'prod', 'staging', 'dev', 'UAT'"
}

variable "name" {
  type        = string
  description = "Solution name, e.g. 'app' or 'jenkins'"
}

variable "delimiter" {
  type        = string
  default     = null
  description = <<-EOT
    Delimiter to be used between `environment`, `stage`, `name`.
    Defaults to `-` (hyphen). Set to `""` to use no delimiter at all.
  EOT
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)."
}

variable "label_order" {
  type        = list(string)
  default     = null
  description = <<-EOT
    The naming order of the id output and Name tag.
    Defaults to [ "environment", "stage", "name"].
    You can omit any of the 3 elements, but at least one must be present.
  EOT
}

variable "tags" {
  type = map(string)
  validation {
    condition     = alltrue([for t in ["Owner", "Team"] : contains(keys(var.tags), t)]) && false == contains(values(var.tags), "")
    error_message = "Please include non-empty tags for Owner and Team."
  }
  description = "Additional tags (e.g. `map('ManagedBy','XYZ')`"
}