# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.5.1"
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/static-assets/asset-catalog-site.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  
  account_name = local.account_vars.locals.account_name
  account_id   = local.common_vars.locals.account_ids[local.account_name]
}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {

  website_domain_name = "assets.${local.account_vars.locals.domain_name.name}"

  enable_waf = false

  # If you need to delete infrastructure set this variable to true and run terraform apply, then delete the module to delete the infra
  force_destroy_bucket = false

  s3_bucket_override_policy_documents = []

  # Asset images have different hash if they are updated and hence setting caching to maximum
  default_ttl = 31536000

  max_ttl = 31536000

  # Cache for 1 month minimum
  min_ttl = 2628288

  enable_viewer_request_edge_lambda = true

  viewer_request_lambda_name = "viewer-request-validate-image"

  enable_origin_response_edge_lambda = true

  origin_response_lambda_name = "origin-response-transform-images"


  enable_origin_shield = true

  origin_shield_region = "us-east-1"

  allowed_http_methods = ["GET", "HEAD", "OPTIONS"]

  log_retention_period = 30

}