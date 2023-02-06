# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for services/frontend-app. The common variables for each environment to
# deploy services/frontend-app are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If you're iterating
# locally, you can use --terragrunt-source /path/to/local/checkout/of/module to override the source parameter to a
# local check out of the module for faster iteration.
terraform {
  source = "${local.source_base_url}?ref=v0.7.11"
}

dependency "common_infra" {
  config_path                             = "${get_terragrunt_dir()}/../../etl/common-infra"
  mock_outputs_allowed_terraform_commands = ["validate", ]
  mock_outputs = {
    get_product_diff_create_images_lambda_qualified_arn = "mock-lambda-arn"
    kms_lambda_access_policy_arn                        = "mock-kms-policy"
    mongo_secret_access_policy_arn                      = "mock-mongo-sercret"
    algolia_secret_access_policy_arn                    = "mock-algolia-sercret"
    partner_data_bucket_name                            = "mock-partner-bucket"
    push_product_data_lambda_qualified_arn              = "mock-push-product"
    partner_data_bucket_policy_arn                      = "mock-partner-data-bucket-policy"
    ingestion_files_bucket_name                         = "mock-ingestion-files-bucket"
    ingestion_files_bucket_policy_arn                   = "mock-ingestion-bucket-policy-arn"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:Furniture-com/fdc-aws-infra-catalog.git//modules/etl/partner-rf-infra"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# This defines the parameters that are common across all environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  step_function_name                        = "rf-state-machine"
  rf_parse_feed_lambda_name                 = "rf-parse-feed"
  rf_predict_images_lambda_name             = "rf-predict-images"
  rf_map_categories_lambda_name             = "rf-map-categories"
  get_product_diff_create_images_lambda_arn = dependency.common_infra.outputs.get_product_diff_create_images_lambda_qualified_arn
  push_product_data_lambda_arn              = dependency.common_infra.outputs.push_product_data_lambda_qualified_arn
  kms_lambda_access_policy_arn              = dependency.common_infra.outputs.kms_lambda_access_policy_arn
  mongo_secret_access_policy_arn            = dependency.common_infra.outputs.mongo_secret_access_policy_arn
  algolia_secret_access_policy_arn          = dependency.common_infra.outputs.algolia_secret_access_policy_arn
  partner_data_bucket_name                  = dependency.common_infra.outputs.partner_data_bucket_name
  partner_data_bucket_policy_arn            = dependency.common_infra.outputs.partner_data_bucket_policy_arn
  ingestion_files_bucket_name               = dependency.common_infra.outputs.ingestion_files_bucket_name
  ingestion_files_bucket_policy_arn         = dependency.common_infra.outputs.ingestion_files_bucket_policy_arn
}

