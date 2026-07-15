# OpenTofu Infrastructure

This directory contains the OpenTofu configuration for the AWS infrastructure used by the Meili's Soap Store catalog demo.

The stack serves the static storefront through CloudFront and routes `/api/*` requests to API Gateway. API Gateway uses a direct AWS service integration to retrieve product data from the DynamoDB `ProductCatalog` table, while VTL mapping templates convert the DynamoDB response into the JSON structure expected by the existing frontend.

## Architecture

```text
Browser
  -> CloudFront
      -> S3 for HTML, CSS, JavaScript, and images
      -> API Gateway for /api/* requests
          -> DynamoDB ProductCatalog table
```

## What It Manages

The OpenTofu configuration includes the resources needed for the current deployment, including:

- Route 53 hosted zone and DNS records for the custom domain
- ACM certificate in `us-east-1` for CloudFront
- CloudFront origin access control for the S3 origin
- CloudFront distribution with:
  - A private S3 origin for static website files
  - An API Gateway origin for `/api/*` requests
  - Path-based routing between the S3 and API origins
  - HTTP-to-HTTPS redirects
- API Gateway REST API
- API Gateway `/products` resource and `GET` method
- Direct API Gateway integration with DynamoDB
- VTL request and response mapping templates
- DynamoDB `ProductCatalog` table
- IAM role and policy allowing API Gateway to scan the catalog table
- S3 bucket policy allowing reads through CloudFront
- Optional AWS WAF configuration

## What It Does Not Manage

The current configuration does not manage:

- The existing S3 bucket itself
- Static website files stored in the S3 bucket
- Product records inserted into the DynamoDB table
- Application deployment workflows
- Domain registration at the registrar

The S3 bucket and domain must already exist or be replaced with values appropriate for your own environment.

## Important

This repository is intended primarily as an architecture and infrastructure-as-code demonstration.

Before running `tofu apply`:

- Review every variable and resource name.
- Confirm which resources already exist in the target AWS account.
- Check for imported resources or state assumptions.
- Replace the example domain, bucket, and naming values when needed.
- Review the expected AWS costs.
- Do not apply the configuration unchanged to an AWS account you do not intend to modify.

## Prerequisites

Before using the configuration, install and configure:

1. [OpenTofu](https://opentofu.org/)
2. AWS CLI
3. AWS credentials with permission to manage the required services
4. Access to the Route 53 hosted zone or domain registrar
5. An existing S3 bucket for the static storefront
6. Product data to insert into the DynamoDB table after creation

The AWS identity being used should have permission to manage resources in:

- Route 53
- ACM
- CloudFront
- API Gateway
- DynamoDB
- IAM
- S3
- WAF, when enabled

## Provider Regions

CloudFront certificates must be created in `us-east-1`, so the configuration uses that region for ACM and other global-service dependencies.

The existing storefront S3 bucket is located in `us-east-2`.

Review the provider configuration and variables before applying the stack in another environment.

## Configuration

Copy the example variables file before planning the deployment:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Then review and update the values in `terraform.tfvars`.

Common values include:

- AWS region
- Domain name
- S3 bucket name
- S3 bucket region
- CloudFront price class
- Minimum TLS version
- Resource tags
- WAF management options

Do not store AWS credentials, private keys, or other secrets in `.tfvars` files.

## Usage

### Initialize the working directory

```bash
tofu init
```

This downloads the required providers and prepares the local working directory.

The committed `.terraform.lock.hcl` file records the provider versions and checksums selected for this project.

### Validate the configuration

```bash
tofu validate
```

### Review the execution plan

```bash
tofu plan
```

Review the plan carefully before applying it, especially when the configuration references existing resources.

### Apply the changes

```bash
tofu apply
```

OpenTofu will display the proposed changes again and request confirmation before modifying the AWS account.

### View outputs

```bash
tofu output
```

Outputs may include values such as:

- CloudFront distribution information
- Route 53 name servers
- API endpoint details
- DynamoDB table name

### Destroy managed resources

```bash
tofu destroy
```

Use this command carefully. Some resources may be connected to the live site or may have been imported into OpenTofu state.

## API Gateway and DynamoDB Integration

The API Gateway integration directly calls DynamoDB instead of invoking a Lambda function.

The request flow is:

1. CloudFront receives a browser request for `/api/products`.
2. The `/api/*` CloudFront behavior sends the request to API Gateway.
3. API Gateway assumes its integration IAM role.
4. API Gateway performs `dynamodb:Scan` against the `ProductCatalog` table.
5. A VTL response mapping template converts DynamoDB's typed attribute format into the JSON contract expected by the frontend.
6. The transformed response is returned to the browser.

The IAM permissions are intentionally limited to scanning the catalog table.

## VTL Mapping Templates

DynamoDB returns values in a typed format such as:

```json
{
  "name": {
    "S": "Example Soap"
  },
  "displayOrder": {
    "N": "1"
  }
}
```

The API Gateway response mapping template converts that format into a simpler frontend response:

```json
{
  "name": "Example Soap",
  "displayOrder": 1
}
```

This allows the frontend to keep using the same product structure that was previously provided by the static JSON file.

## DynamoDB Data

The OpenTofu configuration creates the `ProductCatalog` table, but it does not populate the table with product records.

After the table is created, product data must be added separately through a seeding script, the AWS CLI, the AWS Console, or another deployment process.

The current demo uses a table scan because the catalog contains a small number of products. A larger production catalog would likely benefit from query-oriented access patterns, indexes, pagination, and caching.

## WAF Notes

WAF management is optional.

When WAF creation is disabled, the configuration can continue using an existing or separately managed CloudFront protection configuration. Review the current variables and imported-resource state before enabling a new Web ACL.

## State and Generated Files

The following files and directories should not be committed:

```text
.terraform/
*.tfstate
*.tfstate.*
.terraform.tfstate.lock.info
crash.log
crash.*.log
```

The following file should normally remain committed:

```text
.terraform.lock.hcl
```

The lock file helps keep provider selection consistent across machines and CI environments.

## Related Project Documentation

See the repository-level [`README.md`](../README.md) for:

- The project overview
- The before-and-after architecture
- The frontend integration
- The request flow
- Screenshots of the deployed AWS resources
- A link to the live website