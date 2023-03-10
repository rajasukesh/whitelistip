# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.35.1"
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/landingzone/account-baseline-app-base.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  common_vars    = include.envcommon.locals.common_vars
  accounts       = local.common_vars.locals.accounts
  account_ids    = include.envcommon.locals.account_ids
  aws_region     = include.envcommon.locals.aws_region
  opt_in_regions = include.envcommon.locals.opt_in_regions

  # For CIS Compliance, we use the logs account as the administrator account for some services (SecurityHub and Macie),
  # so we define a local here for the accounts that need to report to this account.
  external_member_accounts = {
    for name, account_info in local.accounts :
    name => {
      account_id = account_info.id
      email      = account_info.root_user_email
    }
    if name != "logs"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  ################################
  # Parameters for AWS Config
  ################################
  # This is the Logs account, so we create the S3 bucket and SNS topic for aggregating Config logs from all accounts.
  config_should_create_s3_bucket = true
  config_should_create_sns_topic = true

  # All of the other accounts send logs to this account.
  config_linked_accounts = [
    for name, id in local.account_ids :
    id if name != "logs"
  ]

  ################################
  # Parameters for CloudTrail
  ################################
  # This is the Logs account, so we create the S3 bucket for aggregating CloudTrail logs from all accounts.
  cloudtrail_s3_bucket_already_exists = false

  # All of the other accounts send logs to this account.
  cloudtrail_allow_kms_describe_key_to_external_aws_accounts = true
  cloudtrail_external_aws_account_ids_with_write_access = [
    for name, id in local.account_ids :
    id if name != "logs"
  ]

  # The ARN is a key alias, not a key ID. This variable prevents a perpetual diff when using an alias.
  cloudtrail_kms_key_arn_is_alias = true

  # By granting access to the root ARN of the Logs account, we allow administrators to further delegate to access
  # other IAM entities
  cloudtrail_kms_key_administrator_iam_arns = ["arn:aws:iam::${local.account_ids.logs}:root"]
  cloudtrail_kms_key_user_iam_arns          = ["arn:aws:iam::${local.account_ids.logs}:root"]

  # Do not allow objects in the CloudTrail S3 bucket to be forcefully removed during destroy operations.
  cloudtrail_force_destroy = false
  ##################################
  # CONFIGURATION FOR CIS
  ##################################
  # Create the alarms topic in the logs account
  cloudtrail_benchmark_alarm_sns_topic_already_exists = false
  cloudtrail_benchmark_alarm_sns_topic_name           = "BenchmarkAlarmTopic"

  # The logs account acts as the administrator account for SecurityHub and Macie, so add the rule to invite the other
  # accounts.
  security_hub_external_member_accounts = local.external_member_accounts
  macie_external_member_accounts        = local.external_member_accounts
}
