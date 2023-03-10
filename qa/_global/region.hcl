# Modules in the account _global folder don't live in any specific AWS region, but you still have to send the API calls
# to _some_ AWS region, so here we pick a default region to use for those API calls.
locals {
  # Automatically load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  aws_region   = "us-east-1"
  state_bucket = lower("${local.common_vars.locals.name_prefix}-${local.account_vars.locals.account_name}-${local.aws_region}-tf-state")
}
