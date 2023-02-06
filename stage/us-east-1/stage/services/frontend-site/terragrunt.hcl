# This is the configuration for Terragrunt, a thin wrapper for Terraform: https://terragrunt.gruntwork.io/

# Override the terraform source with the actual version we want to deploy.
terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.6.5-rc"
}

# Include the root `terragrunt.hcl` configuration, which has settings common across all environments & components.
include "root" {
  path = find_in_parent_folders()
}

# Include the component configuration, which has settings that are common for the component across all environments
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/services/frontend-site.hcl"
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

  ipv4Ranges = yamldecode(file("ipv4.yaml"))["ipList"]
  ipv6Ranges = yamldecode(file("ipv6.yaml"))["ipList"]  
}

# ---------------------------------------------------------------------------------------------------------------------
# Module parameters to pass in. Note that these parameters are environment specific.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {

  service_container_cpu = 4096

  service_container_memory = 24576

  service_container_image_link = "nginx"

  service_desired_count = 4

#  scaling_max_capacity = 16

  service_container_port = parseint("80", 10)

  enable_www = true

  enable_distribution = true

  enable_origin_shield = true

  price_class = "PriceClass_100"

  default_ttl  = 43200

  default_max_ttl = 43200

  default_min_ttl = 0

  # stores path set at default cache value of 30 days
  default_stores_path_ttl = 2592000

  max_stores_path_ttl = 2592000

  min_stores_path_ttl = 0

  # If you want to destroy set this true and then run apply and then delete the folder scripts
  enable_alb_deletion_protection = false

  force_destroy_access_logs_bucket = false

  enable_cdn_logging = true

  enable_redirection_lambda = true

  enable_autoscaling = true

  enable_waf_ip = true

  origin_shield_region = "us-east-1"

  dynamodb_replica_regions = [
    "us-east-2",
    "us-west-1",
    "us-west-2",
  ]

  dynamodb_table_name = "site-redirection-table"

  website_domain_name = "${local.account_vars.locals.domain_name.name}"

  ipV4Whitelist = local.ipv4Ranges
  ipV6Whitelist = local.ipv6Ranges
}