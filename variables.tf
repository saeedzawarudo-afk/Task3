variable "container_name" {
  description = "Container name"
  type        = string
  default     = "tf-nginx"
}

variable "external_port" {
  description = "Host port"
  type        = number
  default     = 8080
}
