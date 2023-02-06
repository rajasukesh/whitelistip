
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

  # Extract the name prefix for easy access
  name_prefix = local.common_vars.locals.name_prefix

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Extract the account_name and account_role for easy access
  account_name = local.account_vars.locals.account_name
  account_role = local.account_vars.locals.account_role

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the region for easy access
  aws_region = local.region_vars.locals.aws_region

  # Locals for more convenient access to the region variables
  region       = local.region_vars.locals.aws_region
  state_bucket = local.region_vars.locals.state_bucket

  # A local for more convenient access to the account_ids map.
  account_ids = local.common_vars.locals.account_ids

  # A local for convenient access to the security account root ARN.
  security_account_root_arn = "arn:aws:iam::${local.account_ids.security}:root"

  # A local for convenient access to the shared account root ARN.
  shared_account_root_arn = "arn:aws:iam::${local.account_ids.shared}:root"

  # Read in the permissions from the ecs-deploy-runner, which will be in the _envcommon folder.
  iam_policy = yamldecode(
    templatefile(
      "${dirname(find_in_parent_folders())}/_envcommon/mgmt/jenkins_deploy_permissions.yml",
      {
        state_bucket = local.state_bucket
      },
    ),
  )

}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  should_require_mfa      = false
  should_create_iam_group = false
  should_create_iam_role  = true

  iam_role_name    = "allow-jenkins-deploy-access-from-other-accounts"
  assume_role_arns = [local.security_account_root_arn, local.shared_account_root_arn]
  iam_policy       = local.iam_policy
}