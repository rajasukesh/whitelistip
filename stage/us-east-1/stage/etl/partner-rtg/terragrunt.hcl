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
    cleanup_lambda_qualified_arn           = "mock-lambda-arn"
    consolidate_slugs_lambda_qualified_arn = "mock-consolidate-slugs-arn"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/etl/partner-rtg.hcl"
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

}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  fetch_pla_data_lambda_reserved_concurrency       = 100
  fetch_pla_data_lambda_timeout                    = 900
  fetch_pla_data_lambda_memory_size                = 4096
  fetch_rtg_api_data_lambda_timeout                = 900
  fetch_rtg_api_data_lambda_memory_size            = 4096
  fetch_rtg_api_data_lambda_reserved_concurrency   = 100
  combine_pla_api_data_lambda_timeout              = 900
  combine_pla_api_data_lambda_memory_size          = 8192
  combine_pla_api_data_lambda_reserved_concurrency = 100
  # Logs stored for 1 week
  log_retention_period = 7
  enable_scheduler     = true
  # Pipeline runs at 06:00 a.m UTC everyday
  trigger_schedule_expression            = "cron(0 6 * * ? *)"
  secret_manager_secret_retention_period = 30
  state_machine_trigger_input_payload = {
    "partnerTag"  = "RTG",
    "partnerName" = "Rooms To Go",
    "primaryFeed" = "https://plafeeds.s3.amazonaws.com/DEV_rtg_fdc_primary_product_feed.txt"
  }

  cleanup_lambda_arn           = dependency.common_infra.outputs.cleanup_lambda_qualified_arn
  consolidate_slugs_lambda_arn = dependency.common_infra.outputs.consolidate_slugs_lambda_qualified_arn
}
