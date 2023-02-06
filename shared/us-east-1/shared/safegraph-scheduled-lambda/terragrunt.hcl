
# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform that helps keep your code DRY and
# maintainable: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If you're iterating
# locally, you can use --terragrunt-source /path/to/local/checkout/of/module to override the source parameter to a
# local check out of the module for faster iteration.
terraform {
  source = "${local.source_base_url}?ref=v0.7.7"
}

# Use an override file to lock the provider version, regardless of if required_providers is defined in the modules.
## Required for aws_location_place_index resource
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


dependency "safegraph_role" {
  config_path = "${get_terragrunt_dir()}/../../../_global/safegraph-s3-role"

  mock_outputs = {
    iam_role_arn = "mock-lambda-arn"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:Furniture-com/fdc-aws-infra-catalog.git//modules/services/scheduled-lambda-job"

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  name = "get-safegraph-store-data"
  lambda_runtime = "nodejs16.x"
  memory_size = 2048
  description = "Lambda function to pull safegraph data and generate store slugs/data and push to algolia"
  create_secret = true
  secret_name = "safeGraphAlgoliaSecret"
  create_bucket = true
  enable_location_service = true
  bucket_name = "fdc-safegraph-data"
  force_destroy = false
  log_retention_period = 90
  environment_variables = {
    safegraphBucketName = "fdc-safegraph-data"
  }
  existing_role_arn = dependency.safegraph_role.outputs.iam_role_arn
  schedule_expression = "cron(0 0 2 * ? *)"
  bucket_lifecycle_rules = {
    DeleteOldObjects = {
      enabled = true
      expiration = {
        days = {
          days = 180
        }
      }
    }
  }
  lambda_trigger_input = {
    "sourceBucket": "safegraph-places-outgoing",
    "destinationBuckets": [
      "partner-execution-data-mlmktcbj",
      "partner-execution-data-lgrzxubt",
      "partner-execution-data-rbzoiscn",
      "partner-execution-data-olumpncv",
    ],
    "algoliaIndices": [
      "stores_dev",
      "stores_stage",
      "stores_qa",
      "stores_prod",
    ]
  }
}