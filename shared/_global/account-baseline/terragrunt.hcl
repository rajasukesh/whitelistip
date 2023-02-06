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
  # KMS keys
  ##################################

  kms_customer_master_keys = merge(
    include.envcommon.locals.base_kms_keys,
    {
      # The `shared-secrets` key is used to encrypt AWS Secrets Manager secrets that are shared with other accounts.
      shared-secrets = {
        cmk_administrator_iam_arns = ["arn:aws:iam::${local.account_ids.shared}:root"]
        cmk_user_iam_arns = [{
          name       = ["arn:aws:iam::${local.account_ids.shared}:root"]
          conditions = []
        }]
        cmk_external_user_iam_arns = [
          for name, id in local.account_ids :
          "arn:aws:iam::${id}:root" if name != "shared"
        ]
      }

      # The `ami-encryption` key is used to encrypt AMIs that are shared with other accounts.
      ami-encryption = {
        cmk_administrator_iam_arns = ["arn:aws:iam::${local.account_ids.shared}:root"]
        cmk_user_iam_arns = [{
          name = [
            "arn:aws:iam::${local.account_ids.shared}:root",

            # The autoscaling service-linked role uses this key when invoking AutoScaling actions
            # (e.g. for adding and removing instances in autoscaling groups).
            "arn:aws:iam::${local.account_ids.shared}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
          ]
          conditions = []
        }]
        cmk_external_user_iam_arns = [
          for name, id in local.account_ids :
          "arn:aws:iam::${id}:root" if name != "shared"
        ]
      }
    },
  )

  # Set the default EBS key to be the AMI encryption key.
  ebs_use_existing_kms_keys = true
  ebs_kms_key_name          = "ami-encryption"
  ebs_opt_in_regions        = local.opt_in_regions
  ##################################
  # CONFIGURATION FOR CIS
  ##################################
  # The ARN of an SNS topic for sending alarms about CIS Benchmark compliance issues.
  # The topic exists in the logs account
  cloudtrail_benchmark_alarm_sns_topic_arn = "arn:aws:sns:${local.aws_region}:${local.account_ids.logs}:BenchmarkAlarmTopic"

  security_hub_associate_to_master_account_id = local.account_ids.logs
}
