variable "cluster_name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "node_count" { type = number }
variable "node_vm_size" { type = string }
variable "min_count" { type = number }
variable "max_count" { type = number }
variable "subnet_id" { type = string }
variable "log_analytics_workspace_id" { type = string }

variable "availability_zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "private_cluster_enabled" {
  type    = bool
  default = true
}
