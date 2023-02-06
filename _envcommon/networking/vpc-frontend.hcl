# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for networking/vpc-app. The common variables for each environment to
# deploy networking/vpc-app are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If you're iterating
# locally, you can use --terragrunt-source /path/to/local/checkout/of/module to override the source parameter to a
# local check out of the module for faster iteration.
terraform {
  source = "${local.source_base_url}?ref=v0.41.2"
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:gruntwork-io/terraform-aws-cis-service-catalog.git//modules/networking/vpc"

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

  cidr_block = local.common_vars.locals.app_vpc_cidrs[local.account_name]
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# This defines the parameters that are common across all environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  vpc_name         = "vpc-frontend"
  num_nat_gateways = 1
  cidr_block       = local.cidr_block
  kms_key_user_iam_arns = [
    "arn:aws:iam::${local.common_vars.locals.account_ids[local.account_name]}:root",
  ]

  allow_administrative_remote_access_cidrs_public_subnets = {}

  # Set large enough rule number to provide ample headroom when creating the administrative remote access NACL rules
  initial_deny_rule_number = 200
  allow_all_rule_number    = 500
}