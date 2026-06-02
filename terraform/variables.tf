variable "remote_state_bucket" {
  type = string
}

variable "remote_state_prefix" {
  type    = string
  default = "healthcare-app/terraform"
}
