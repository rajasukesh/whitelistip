# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common override configuration for account-baseline-app for app accounts. This configuration will be merged
# into the environment configuration via an include block.
# NOTE: This configuration MUST be included with _envcommon/account-baseline-app-base.hcl
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Automatically load common variables shared across all accounts
  common_vars       = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  accounts          = local.common_vars.locals.accounts
  account_ids       = local.common_vars.locals.account_ids
  multi_region_vars = read_terragrunt_config(find_in_parent_folders("multi_region_common.hcl"))
  opt_in_regions    = local.multi_region_vars.locals.opt_in_regions

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_name = local.account_vars.locals.account_name
  account_role = local.account_vars.locals.account_role

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  aws_region  = local.region_vars.locals.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above. This
# defines the parameters that are common across all environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  ################################
  # Parameters for AWS Config
  ################################
  # This account sends logs to the Logs account.
  config_aggregate_config_data_in_external_account = true

  # The ID of the Logs account.
  config_central_account_id = local.account_ids.logs
  ################################
  # Parameters for CloudTrail
  ################################
  # Encrypt CloudTrail logs using a common KMS key.
  cloudtrail_kms_key_arn = "arn:aws:kms:us-east-1:540425906777:alias/cloudtrail-furnituredc"

  # The ARN is a key alias, not a key ID. This variable prevents a perpetual diff when using an alias.
  cloudtrail_kms_key_arn_is_alias = true
  ##################################
  # CONFIGURATION FOR CIS
  ##################################
  # The ARN of an SNS topic for sending alarms about CIS Benchmark compliance issues.
  # The topic exists in the logs account
  cloudtrail_benchmark_alarm_sns_topic_arn = "arn:aws:sns:${local.aws_region}:${local.account_ids.logs}:BenchmarkAlarmTopic"

  security_hub_associate_to_master_account_id = local.account_ids.logs
  macie_administrator_account_id              = local.account_ids.logs
}
