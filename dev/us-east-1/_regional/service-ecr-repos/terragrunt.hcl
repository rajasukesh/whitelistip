
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
  source = "${local.source_base_url}?ref=v0.90.2"
}
# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:gruntwork-io/terraform-aws-service-catalog.git//modules/data-stores/ecr-repos"

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

  # Use a data file to load in the repos input. We use a YAML file as opposed to inlining the repos as a local to allow
  # the Gruntwork Architecture Catalog to inject additional repository configurations as additional templates are
  # invoked.
  repos = {
    fdc-frontend = {
        external_account_ids_with_read_access = [local.common_vars.locals.account_ids.dev]
        external_account_ids_with_write_access = [local.common_vars.locals.account_ids.dev]
        enable_automatic_image_scanning = true
        image_tag_mutability = "MUTABLE"
        lifecycle_policy_rules = {
            rules = [
            {
                rulePriority = 1
                description = "Expire images older than 10 days"
                selection = {
                    tagStatus = "any"
                    countType = "sinceImagePushed"
                    countUnit = "days"
                    countNumber = 10
                }
                action = {
                    type = "expire"
                }
             }
            ]
        }
    }
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  repositories = local.repos
}