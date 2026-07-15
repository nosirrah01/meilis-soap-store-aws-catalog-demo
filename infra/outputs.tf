output "route53_zone_id" {
  description = "ID of the Route 53 hosted zone for the domain."
  value       = aws_route53_zone.main.zone_id
}

output "route53_name_servers" {
  description = "Delegation name servers that must be configured at the registrar."
  value       = aws_route53_zone.main.name_servers
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "certificate_arn" {
  description = "ACM certificate ARN used by CloudFront."
  value       = aws_acm_certificate_validation.site.certificate_arn
}

output "website_url" {
  description = "Public HTTPS URL for the storefront."
  value       = "https://${var.domain_name}"
}