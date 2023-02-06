# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.7.11"
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

dependency "common_infra" {
  config_path = "${get_terragrunt_dir()}/../../etl/common-infra"

  mock_outputs = {
    cleanup_lambda_qualified_arn = "mock-lambda-arn"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/etl/partner-gw.hcl"
  expose = true
}


# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  gw_fetch_transform_data_lambda_reserved_concurrency   = 10
  gw_fetch_transform_data_lambda_timeout                = 900
  gw_fetch_transform_data_lambda_memory_size            = 8192
  gw_store_transformed_data_lambda_timeout              = 900
  gw_store_transformed_data_lambda_memory_size          = 4096
  gw_store_transformed_data_lambda_reserved_concurrency = 500
  cleanup_lambda_arn                                    = dependency.common_infra.outputs.cleanup_lambda_qualified_arn
  consolidate_slugs_lambda_arn                          = dependency.common_infra.outputs.consolidate_slugs_lambda_qualified_arn

  # Do not use in production
  force_destroy_bucket = false

  ingestion_bucket_access_role_arn_list = [
    "arn:aws:iam::980279442813:role/transfer-sftp-data"
  ]
  # Cloudwatch allows only certain number of days for retention
  log_retention_period = 7
  enable_scheduler     = true

  # Runs at 06:00 a.m UTC everyday
  trigger_schedule_expression = "cron(0 6 * * ? *)"

  ingestion_bucket_lifecycle_rules = {
    DeleteArchiveData = {
      enabled = true
      prefix  = "archive/"
      expiration = {
        days = {
          days = 10
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
