# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.6.2-rc"
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/services/backend-api-gateway.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  
  account_name = local.account_vars.locals.account_name
  account_id   = local.common_vars.locals.account_ids[local.account_name]
}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {

  disable_execute_api_endpoint = false

  rest_api_specification = jsonencode(file("${get_terragrunt_dir()}/../backend-api-gateway/openapi-spec.json"))

  stage_name = "v1"

  api_domain_name = "api.${local.account_vars.locals.domain_name.name}"

  base_domain_name = "${local.account_vars.locals.domain_name.name}"

  stage_description = "v1 deployment to stage"

  lambda_function_names = [
    "get-geo-information",
    "get-rules-context",
    "get-zip-by-location",
    "retool-update-products-service",
    "arn:aws:lambda:us-east-1:666478967164:function:get-geo-information:stage",
    "arn:aws:lambda:us-east-1:666478967164:function:get-zip-by-location:stage",
    "arn:aws:lambda:us-east-1:666478967164:function:get-rules-context:stage",
    "arn:aws:lambda:us-east-1:666478967164:function:retool-update-products-service:stage"
  ]

}



