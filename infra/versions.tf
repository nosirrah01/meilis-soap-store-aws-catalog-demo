terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Additional provider for us-east-2 (your API Gateway and DynamoDB)
provider "aws" {
  alias  = "us_east_2"
  region = "us-east-2"

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "bucket"
  region = var.s3_bucket_region

  default_tags {
    tags = local.common_tags
  }
}