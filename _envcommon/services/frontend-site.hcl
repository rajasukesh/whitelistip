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
  source = "${local.source_base_url}?ref=v0.6.5-rc"
}



# Use an override file to lock the provider version, regardless of if required_providers is defined in the modules.
generate "provider_version" {
  path      = "provider_version_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.45.0"
    }
  }
}
EOF
}
# ---------------------------------------------------------------------------------------------------------------------
# Dependencies are modules that need to be deployed before this one.
# ---------------------------------------------------------------------------------------------------------------------

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../../networking/vpc"

  mock_outputs = {
    vpc_id            = "vpc-abcd1234"
    public_subnet_ids = ["subnet-abcd1234", "subnet-bcd1234a"]
    private_app_subnet_ids = ["subnet-abcd1234", "subnet-bcd1234a"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
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
  source_base_url = "git::git@github.com:Furniture-com/fdc-aws-infra-catalog.git//modules/services/frontend-site"

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

  viewer_protocol_policy = "redirect-to-https"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# This defines the parameters that are common across all environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  
  service_name = "fdc-frontend"

  public_subnet_ids = dependency.vpc.outputs.public_subnet_ids
  private_subnet_ids = dependency.vpc.outputs.private_app_subnet_ids
  vpc_id = dependency.vpc.outputs.vpc_id

  health_check_path = "/"

  allowed_methods = ["GET", "HEAD", "OPTIONS"]

  cached_methods = ["GET", "HEAD", "OPTIONS"]


  viewer_protocol_policy = local.viewer_protocol_policy

  hosted_zone_id = dependency.route53.outputs.public_hosted_zone_map[local.account_vars.locals.domain_name.name]

  base_domain_name = "${local.account_vars.locals.domain_name.name}"
}
