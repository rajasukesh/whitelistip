# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.7.8-rc"
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/static-assets/category-catalog-site.hcl"
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

  website_domain_name = "category.${local.account_vars.locals.domain_name.name}"

  enable_waf = false

  # If you need to delete infrastructure set this variable to true and run terraform apply, then delete the module to delete the infra
  force_destroy_bucket = true

  s3_bucket_override_policy_documents = []

  # Setting this to a high value since category images are not updated frequently
  # If images are updated cloudfront cache needs to be invalidated every time
  # Reduce this ttl if images are updated frequently
  default_ttl = 600

  max_ttl = 600

  min_ttl = 0

  bucket_lifecycle_rules = {
    DeleteOldObjects = {
      enabled = true
      noncurrent_version_expiration = 5
      expiration = {
        expired_object_delete_marker = {
          expired_object_delete_marker = true
        }
      }
    }

    # Adding this rule separately as the deleted objects with delete markers set are not cleaned up with the DeleteOldObjects rule
    RemoveDeleteMarkerObjects = {
      enabled = true
      expiration = {
        expired_object_delete_marker = {
          expired_object_delete_marker = true
        }
      }
    }
  }

  enable_viewer_request_edge_lambda = true
  enable_origin_response_edge_lambda = true

  viewer_request_lambda_name = "viewer-request-validate-category-images"
  origin_response_lambda_name = "origin-response-transform-category-images"

  enable_origin_shield = false

  content_type="image/png"

  override_content_type = false


  allowed_http_methods = ["GET", "HEAD", "OPTIONS"]

}