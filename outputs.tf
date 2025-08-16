output "container_name" {
  value = docker_container.web.name
}

output "container_id" {
  value = docker_container.web.id
}

output "url" {
  value = "http://localhost:${var.external_port}"
}
