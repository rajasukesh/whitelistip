# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.6.5-rc"
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/static-assets/product-catalog-site.hcl"
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

  website_domain_name = "products.${local.account_vars.locals.domain_name.name}"

  enable_waf = false

  # If you need to delete infrastructure set this variable to true and run terraform apply, then delete the module to delete the infra
  force_destroy_bucket = false

  s3_bucket_override_policy_documents = []

  default_ttl = 120

  max_ttl = 300

  min_ttl = 60

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
  }

  enable_origin_shield = false

  content_type="application/json"


  allowed_http_methods = ["GET", "HEAD", "OPTIONS"]

}