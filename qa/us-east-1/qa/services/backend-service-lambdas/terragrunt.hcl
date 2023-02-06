# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.7.8-rc"
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

dependency "common_infra" {
  config_path = "${get_terragrunt_dir()}/../../etl/common-infra"

  mock_outputs = {
    partner_data_bucket_name = "mock-partner-data-bucket-name"
    algolia_secret_access_policy_arn = "mock-algolia-sercret"
    algolia_secret_name = "mock-algolia-secret-name"

  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/services/backend-service-lambda.hcl"
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

  lambda_runtime = "nodejs16.x"

  geocode_service_reserved_concurrency = 10
  geocode_service_timeout = 300
  geocode_memory_size = 4096
  


  zipcode_service_reserved_concurrency = 10
  zipcode_service_timeout = 300
  zipcode_memory_size = 4096
 


  rules_context_reserved_concurrency = 10
  rules_context_timeout = 300
  rules_context_memory_size = 4096
  

  algolia_secret_access_policy_arn = dependency.common_infra.outputs.algolia_secret_access_policy_arn
  algolia_secret_name = dependency.common_infra.outputs.algolia_secret_name

  partner_execution_data_bucket = dependency.common_infra.outputs.partner_data_bucket_name
  product_bucket = "products.fdc-qa.com"

  retool_timeout = 900
  retool_memory_size = 4096
  retool_reserved_concurrency = 5

  secret_manager_secret_retention_period = 0

  log_retention_period = 30

}