output "instance_name" {
  description = "Name of the Compute Engine instance"
  value       = google_compute_instance.dify_instance.name
}

output "instance_id" {
  description = "ID of the Compute Engine instance"
  value       = google_compute_instance.dify_instance.id
}

output "instance_zone" {
  description = "Zone of the Compute Engine instance"
  value       = google_compute_instance.dify_instance.zone
}

output "static_ip_address" {
  description = "Static external IP address"
  value       = google_compute_address.dify_static_ip.address
}

output "ssh_connection_command" {
  description = "Command to SSH into the instance"
  value       = "gcloud compute ssh ${var.ssh_user}@${google_compute_instance.dify_instance.name} --zone=${var.zone} --project=${var.project_id}"
}

output "dns_configuration" {
  description = "DNS configuration instructions"
  value       = "Please create an A record for ${var.domain_name} pointing to ${google_compute_address.dify_static_ip.address}"
}

output "dify_url" {
  description = "Dify application URL"
  value       = "https://${var.domain_name}"
}
