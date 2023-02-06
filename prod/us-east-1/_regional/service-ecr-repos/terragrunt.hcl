
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


  repos = {
    fdc-frontend = {
        external_account_ids_with_read_access = [local.common_vars.locals.account_ids.stage]
        external_account_ids_with_write_access = [local.common_vars.locals.account_ids.stage]
        enable_automatic_image_scanning = true
        image_tag_mutability = "MUTABLE"
        lifecycle_policy_rules = {
            rules = [
            {
                rulePriority = 1
                description = "Expire images older than 180 days"
                selection = {
                    tagStatus = "any"
                    countType = "sinceImagePushed"
                    countUnit = "days"
                    countNumber = 180
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