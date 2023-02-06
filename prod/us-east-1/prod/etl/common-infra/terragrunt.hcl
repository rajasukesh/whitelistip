# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.7.11"
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/etl/common-infra.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  image_bucket_name                                          = "assets.${local.account_vars.locals.domain_name.name}"
  product_bucket_name                                        = "products.${local.account_vars.locals.domain_name.name}"
  cleanup_lambda_name                                        = "common-remove-deleted-products"
  consolidate_slugs_lambda_name                              = "common-combine-product-slugs"
  consolidate_slugs_lambda_timeout                           = 900
  consolidate_slugs_lambda_memory_size                       = 8192
  cleanup_lambda_timeout                                     = 900
  cleanup_lambda_memory_size                                 = 5120
  push_product_data_lambda_timeout                           = 900
  push_product_data_lambda_memory_size                       = 8192
  force_destroy_bucket                                       = false # Set to true and apply if you want to destroy infrastructure
  log_retention_period                                       = 30
  cleanup_lambda_reserved_concurrency                        = 10
  consolidate_slugs_lambda_reserved_concurrency              = 10
  push_product_data_lambda_reserved_concurrency              = 500
  get_product_diff_create_images_lambda_memory_size          = 8192
  get_product_diff_create_images_lambda_timeout              = 900
  get_product_diff_create_images_lambda_reserved_concurrency = 500
  secret_manager_secret_retention_period                     = 30 # Set to 0 only for dev env. Do not use this in production/staging
  partner_data_bucket_access_role_arn_list                   = ["arn:aws:iam::980279442813:role/access-safegraph-s3-bucket"]

  //TODO: Instead of expiration move it to glacier, IA tier
  partner_bucket_lifecycle_rules = {
    DeleteRTGObjects = {
      enabled = true
      prefix  = "Rooms To Go/"
      expiration = {
        days = {
          days = 7
        }
      }
    }

    DeleteAmazonObjects = {
      enabled = true
      prefix  = "Amazon/"
      expiration = {
        days = {
          days = 30
        }
      }
    }

    DeleteGWObjects = {
      enabled = true
      prefix  = "Gardner White/"
      expiration = {
        days = {
          days = 7
        }
      }
    }

    DeleteRFObjects = {
      enabled = true
      prefix  = "Raymour & Flanigan/"
      expiration = {
        days = {
          days = 7
        }
      }
    }

    RemoveDeleteMarkerObjects = {
      enabled = true
      expiration = {
        expired_object_delete_marker = {
          expired_object_delete_marker = true
        }
      }
    }

  }
}
