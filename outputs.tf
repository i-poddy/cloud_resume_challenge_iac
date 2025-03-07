output "project_name" {
  description = "The name of the Project"
  value       = var.project_name
}

output "cloudfront_url" {
  description = "Output the cloudfront distribution URL to check the website"
  value       = aws_cloudfront_distribution.website_distribution.domain_name
}

