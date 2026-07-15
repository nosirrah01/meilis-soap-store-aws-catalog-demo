locals {
  common_tags = merge(
    {
      Project   = "meilis-soap-store"
      ManagedBy = "OpenTofu"
      Domain    = var.domain_name
    },
    var.tags,
  )
}

data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "product_catalog_api" {
  provider = aws.us_east_2

  name        = "product-catalog-api"
  description = "Product Catalog API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(local.common_tags, {
    Name = "product-catalog-api"
  })
}

resource "aws_dynamodb_table" "product_catalog" {
  provider = aws.us_east_2

  name         = "ProductCatalog"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "productId"

  attribute {
    name = "productId"
    type = "S"
  }

  deletion_protection_enabled = false

  point_in_time_recovery {
    enabled = false
  }

  server_side_encryption {
    enabled = false
  }

  tags = merge(local.common_tags, {
    Name = "ProductCatalog"
  })
}

resource "aws_iam_role" "api_gateway_dynamodb_role" {
  provider = aws.us_east_2

  name                 = "APIGatewayToDynamoDBScan"
  path                 = "/"
  description          = "Allows API Gateway to scan the ProductCatalog DynamoDB table."
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Sid = ""
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_logs" {
  provider = aws.us_east_2

  role       = aws_iam_role.api_gateway_dynamodb_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy" "dynamodb_scan" {
  provider = aws.us_east_2

  name = "DynamoDB-ProductCatalog-Scan"
  role = aws_iam_role.api_gateway_dynamodb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:Scan"]
        Resource = aws_dynamodb_table.product_catalog.arn
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_api_gateway_resource" "api" {
  provider = aws.us_east_2

  rest_api_id = aws_api_gateway_rest_api.product_catalog_api.id
  parent_id   = aws_api_gateway_rest_api.product_catalog_api.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "products" {
  provider = aws.us_east_2

  rest_api_id = aws_api_gateway_rest_api.product_catalog_api.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "products"
}

resource "aws_api_gateway_method" "products_get" {
  provider = aws.us_east_2

  rest_api_id      = aws_api_gateway_rest_api.product_catalog_api.id
  resource_id      = aws_api_gateway_resource.products.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "products_get" {
  provider = aws.us_east_2

  rest_api_id = aws_api_gateway_rest_api.product_catalog_api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.products_get.http_method

  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:us-east-2:dynamodb:action/Scan"
  credentials             = aws_iam_role.api_gateway_dynamodb_role.arn
  timeout_milliseconds    = 29000

  request_templates = {
    "application/json" = jsonencode({
      TableName = aws_dynamodb_table.product_catalog.name
    })
  }
}

resource "aws_api_gateway_method_response" "products_get_200" {
  provider = aws.us_east_2

  rest_api_id = aws_api_gateway_rest_api.product_catalog_api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.products_get.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "products_get_200" {
  provider = aws.us_east_2

  rest_api_id = aws_api_gateway_rest_api.product_catalog_api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.products_get.http_method
  status_code = aws_api_gateway_method_response.products_get_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = <<EOF
#set($items = $input.path('$.Items'))
[
#foreach($item in $items)
  {
    "name": "$item.name.S.replaceAll('"', '\\\"')",
    "imageSrc": "$item.imageSrc.S.replaceAll('"', '\\\"')",
    "imageAlt": "$item.imageAlt.S.replaceAll('"', '\\\"')",
    "description": "$item.description.S.replaceAll('"', '\\\"')",
    "priceValue": "$item.priceValue.S.replaceAll('"', '\\\"')",
    "priceDisplay": "$item.priceDisplay.S.replaceAll('"', '\\\"')",
    "availability": "$item.availability.S.replaceAll('"', '\\\"')",
    "moreInfoUrl": "$item.moreInfoUrl.S.replaceAll('"', '\\\"')"
  }#if($foreach.hasNext),#end
#end
]
EOF
  }

  depends_on = [
    aws_api_gateway_integration.products_get,
  ]
}

resource "aws_api_gateway_deployment" "api_deployment" {
  provider = aws.us_east_2

  rest_api_id = aws_api_gateway_rest_api.product_catalog_api.id
  description = "Deployment for API changes"

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.api.id,
      aws_api_gateway_resource.products.id,
      aws_api_gateway_method.products_get.id,
      aws_api_gateway_integration.products_get.id,
      aws_api_gateway_method_response.products_get_200.id,
      aws_api_gateway_integration_response.products_get_200.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.products_get,
    aws_api_gateway_integration.products_get,
    aws_api_gateway_method_response.products_get_200,
    aws_api_gateway_integration_response.products_get_200,
  ]
}

resource "aws_api_gateway_stage" "dev" {
  provider = aws.us_east_2

  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.product_catalog_api.id
  stage_name    = "dev"

  xray_tracing_enabled = false

  tags = local.common_tags
}

resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = merge(local.common_tags, {
    Name = var.domain_name
  })
}

resource "aws_acm_certificate" "site" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = var.domain_name
  })
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "site" {
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "meilis-soap-store-oac"
  description                       = "OAC for meilis-soap-store-web-dev bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_wafv2_web_acl" "cloudfront" {
  count = var.create_waf ? 1 : 0

  name  = "CreatedByCloudFront-2d54e828"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CreatedByCloudFront-2d54e828"
    sampled_requests_enabled   = true
  }

  tags = merge(local.common_tags, {
    Name = "CreatedByCloudFront-2d54e828"
  })
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  price_class         = var.price_class
  http_version        = "http2"

  origin {
    domain_name              = "${var.s3_bucket_name}.s3.${var.s3_bucket_region}.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
    origin_id                = "${var.s3_bucket_name}.s3.${var.s3_bucket_region}.amazonaws.com-mqa13cnjl79"
  }

  origin {
    domain_name = "${aws_api_gateway_rest_api.product_catalog_api.id}.execute-api.us-east-2.amazonaws.com"
    origin_id   = "${aws_api_gateway_rest_api.product_catalog_api.id}.execute-api.us-east-2.amazonaws.com"
    origin_path = "/dev"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.s3_bucket_name}.s3.${var.s3_bucket_region}.amazonaws.com-mqa13cnjl79"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  }

  ordered_cache_behavior {
    path_pattern             = "/api/*"
    allowed_methods          = ["GET", "HEAD"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "${aws_api_gateway_rest_api.product_catalog_api.id}.execute-api.us-east-2.amazonaws.com"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = var.minimum_tls_version
  }

  web_acl_id = var.create_waf ? aws_wafv2_web_acl.cloudfront[0].arn : null

  tags = merge(local.common_tags, {
    Name = "${var.domain_name}-distribution"
  })
}

resource "aws_route53_record" "website" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "S3PolicyStmt-DO-NOT-MODIFY-1778550708749"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "existing_bucket" {
  provider = aws.bucket
  bucket   = var.s3_bucket_name
  policy   = data.aws_iam_policy_document.bucket_policy.json
}
