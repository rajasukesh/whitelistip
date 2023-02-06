
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
  source = "${local.source_base_url}?ref=v0.65.6"
}
# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:gruntwork-io/terraform-aws-security.git//modules/custom-iam-entity"

  # Automatically load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  
  # A local for more convenient access to the account_ids map.
  account_ids = local.common_vars.locals.account_ids

  # A local for convenient access to the security account root ARN.
  security_account_root_arn = "arn:aws:iam::${local.account_ids.security}:root"

  custom_iam_policy_json_name = "safegraph-bucket-access-policy"


}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  # This variable is ignored due to assume_role_iam_policy_json variable
  should_require_mfa      = false
  should_create_iam_group = false
  should_create_iam_role  = true

  iam_role_name    = "access-safegraph-s3-bucket"
  # This variable is ignored due to assume_role_iam_policy_json variable but its specified as mandatory in the module readme so keeping it
  assume_role_arns = [local.security_account_root_arn]
  assume_role_iam_policy_json = templatefile("${get_terragrunt_dir()}/assume_role_policy.json", {})
  iam_policy_json = templatefile("${get_terragrunt_dir()}/s3_iam_policy.json", {})
  iam_policy_json_name = local.custom_iam_policy_json_name
}