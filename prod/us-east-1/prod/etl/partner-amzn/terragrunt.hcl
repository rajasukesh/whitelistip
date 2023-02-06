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
    consolidate_slugs_lambda_qualified_arn = "mock-consolidate-slugs-arn"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/etl/partner-amzn.hcl"
  expose = true
}


# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  amzn_start_map_lambda_reserved_concurrency      = 20
  amzn_start_map_lambda_timeout                   = 900
  amzn_start_map_lambda_memory_size               = 5120
  amzn_search_items_lambda_reserved_concurrency   = 20
  amzn_search_items_lambda_timeout                = 900
  amzn_search_items_lambda_memory_size            = 5120
  amzn_add_variations_lambda_reserved_concurrency = 20
  amzn_add_variations_lambda_timeout              = 900
  amzn_add_variations_lambda_memory_size          = 5120
  amzn_get_variations_lambda_reserved_concurrency = 20
  amzn_get_variations_lambda_timeout              = 900
  amzn_get_variations_lambda_memory_size          = 5120
  amzn_transform_data_lambda_reserved_concurrency = 20
  amzn_transform_data_lambda_timeout              = 900
  amzn_transform_data_lambda_memory_size          = 5120
  log_retention_period                            = 30
  enable_scheduler                                = true

  consolidate_slugs_lambda_arn = dependency.common_infra.outputs.consolidate_slugs_lambda_qualified_arn

  secret_manager_secret_retention_period = 30
  # This is in this format as terraform does not allow creation of multiple different type of resources using a list 
  # This runs at 06:00 am UTC every week on Sunday
  state_machine_scheduler = {
    1 = {
      cron_expression = "cron(0 6 ? * 1 *)"
      payload         = "{}"
    }
  }
}
