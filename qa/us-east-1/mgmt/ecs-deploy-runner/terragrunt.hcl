# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.90.3"
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/mgmt/ecs-deploy-runner.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Dependencies are modules that need to be deployed before this one.
# ---------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  ec2_worker_pool_configuration = {
    ami_filters = {
      owners = [local.common_vars.locals.account_ids.shared]
      filters = [
        {
          name   = "name"
          values = ["ecs-deploy-runner-worker-v0.90.3-*"]
          # TODO: update all ecs-deploy-runners with upgraded v0.90.3 tag 
        },
      ]
    }
    instance_type = "m5.2xlarge"
  }
}