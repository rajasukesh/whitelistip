# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for services/frontend-app. The common variables for each environment to
# deploy services/frontend-app are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If you're iterating
# locally, you can use --terragrunt-source /path/to/local/checkout/of/module to override the source parameter to a
# local check out of the module for faster iteration.
terraform {
  source = "${local.source_base_url}?ref=v0.5.0"
}

dependency "route53" {
  config_path = "${get_terragrunt_dir()}/../../../../_global/route53-public"

  mock_outputs = {
    public_hosted_zone_map = {
      ("${local.account_vars.locals.domain_name.name}") = "some-zone"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:Furniture-com/fdc-aws-infra-catalog.git//modules/static-assets/object-cdn-site"

  # Automatically load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  index_document = "error.html"

  error_document = "error.html"

}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# This defines the parameters that are common across all environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  
  index_document = local.index_document

  error_document = local.error_document

  acm_certificate_domain_name = "${local.account_vars.locals.domain_name.name}"

  enable_versioning = true

  hosted_zone_id = dependency.route53.outputs.public_hosted_zone_map[local.account_vars.locals.domain_name.name]

  cache_response_directive = "must-revalidate"

  price_class = "PriceClass_100"

  content_type = "application/json"

}
