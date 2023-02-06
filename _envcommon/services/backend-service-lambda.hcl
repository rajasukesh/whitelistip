# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for services/backend-service-lambdas. The common variables for each environment to
# deploy services/backend-service-lambdas are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If you're iterating
# locally, you can use --terragrunt-source /path/to/local/checkout/of/module to override the source parameter to a
# local check out of the module for faster iteration.
terraform {
  source = "${local.source_base_url}?ref=v0.6.1-rc"
}

# Use an override file to lock the provider version, regardless of if required_providers is defined in the modules.
generate "provider_version" {
  path      = "provider_version_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16.0"
    }
  }
}
EOF
}


dependency "common_infra" {
  config_path = "${get_terragrunt_dir()}/../../etl/common-infra"

  mock_outputs = {
    kms_lambda_access_policy_arn = "mock-kms-policy"
    mongo_secret_access_policy_arn = "mock-mongo-sercret"
    mongo_db_secret_name = "mock-mongo-secret-name"

  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:Furniture-com/fdc-aws-infra-catalog.git//modules/services/backend-lambdas"

}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# This defines the parameters that are common across all environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  
  location_index_name = "fdc-location-service"
  kms_lambda_access_policy_arn = dependency.common_infra.outputs.kms_lambda_access_policy_arn
  mongo_secret_access_policy_arn = dependency.common_infra.outputs.mongo_secret_access_policy_arn
  mongodb_secret_name = dependency.common_infra.outputs.mongo_db_secret_name
}