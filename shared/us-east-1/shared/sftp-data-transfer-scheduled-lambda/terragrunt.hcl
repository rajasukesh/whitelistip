
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
  source = "${local.source_base_url}?ref=v0.7.0"
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
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl")) # Automatically load account-level variables
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  name           = "transfer-sftp-data"
  lambda_runtime = "nodejs16.x"

  # For the shared account there seems to be a limit on the maximum memory permissible for all lambdas at 3008 mb.
  memory_size          = 2048
  description          = "Lambda function that transfers sftp data from shared to other spokes: dev, stage, prod"
  create_secret        = false
  create_bucket        = false
  force_destroy        = false
  log_retention_period = 90
  schedule_expression  = "cron(0 16 ? * * *)"
  lambda_trigger_input = {
    transferConfig = [
      {
        sourceBucket = "sftp.fdc-shared.com-fcuttyzc",
        destinationBuckets = [
          "gardner-white-ingestion-data-xcjnrsex",
          "gardner-white-ingestion-data-vqgogzed",
          "gardner-white-ingestion-data-dlfubpum",
          "gardner-white-ingestion-data-ezqpbqkz"
        ],
        ingestionFileList = [
          "products.json"
        ],
        sourceFolderPrefix = "GWAdmin"
      },
      {
        sourceBucket       = "sftp.fdc-shared.com-fcuttyzc",
        sourceFolderPrefix = "rfAdmin"
        destinationBuckets = [
          "rf-ingestion-data-erhkqffp",
          "rf-ingestion-data-lbremiwj",
          "rf-ingestion-data-aygcxylu",
          "rf-ingestion-data-otvffzug"
        ],
        ingestionFileList = [
          "FdC_RF_AA.xlsx"
        ],
      },
    ]
  }
}
