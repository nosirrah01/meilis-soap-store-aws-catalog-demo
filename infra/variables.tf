variable "aws_region" {
  description = "Primary AWS region for the OpenTofu stack."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Public domain used for the storefront."
  type        = string
  default     = "meilissoapstore.xyz"
}

variable "s3_bucket_name" {
  description = "Name of the existing S3 bucket that stores the static site assets."
  type        = string
  default     = "meilis-soap-store-web-dev"
}

variable "s3_bucket_region" {
  description = "AWS region where the existing S3 bucket lives."
  type        = string
  default     = "us-east-2"
}

variable "price_class" {
  description = "CloudFront price class used by the distribution."
  type        = string
  default     = "PriceClass_All"
}

variable "minimum_tls_version" {
  description = "Minimum TLS version for the CloudFront viewer certificate."
  type        = string
  default     = "TLSv1.2_2021"
}

variable "create_waf" {
  description = "Whether to create and attach an AWS WAF web ACL to CloudFront."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags applied to all resources."
  type        = map(string)
  default     = {}
}