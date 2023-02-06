# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.35.0"
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/mgmt/vpc-mgmt.hcl"
  # Perform a deep merge so that we can reference dependencies in the override parameters.
  merge_strategy = "deep"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  # We're guarding this functionality with the following "feature flag" so that there's an escape hatch 
  # For anyone who does not wish to have the GruntworkDeployer automatically get access to their accounts
  # To disable this automatic grant, set AllowSSHFromGruntworkDeployer to false
  # Ensure the customer-access-account's deployer's VPC NAT Gateway EIP has access to the customer's shared account VPC
  # Without this, all CIS deployments will fail
  allow_administrative_remote_access_cidrs_public_subnets = { "gruntwork" = "34.197.83.11/32" }
  
}