# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for mgmt/openvpn-server. The common variables for each environment to
# deploy mgmt/openvpn-server are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If you're iterating
# locally, you can use --terragrunt-source /path/to/local/checkout/of/module to override the source parameter to a
# local check out of the module for faster iteration.
terraform {
  source = "${local.source_base_url}?ref=v0.90.2"
}

# ---------------------------------------------------------------------------------------------------------------------
# Dependencies are modules that need to be deployed before this one.
# ---------------------------------------------------------------------------------------------------------------------

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../../networking/vpc"

  mock_outputs = {
    vpc_id            = "vpc-abcd1234"
    vpc_cidr_block    = "10.0.0.0/16"
    public_subnet_ids = ["subnet-abcd1234", "subnet-bcd1234a", ]
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "sns" {
  config_path = "${get_terragrunt_dir()}/../../../_regional/sns-topic"

  mock_outputs = {
    topic_arn = "arn:aws:sns:us-east-1:123456789012:mytopic-NZJ5JSMVGFIE"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  source_base_url = "git::git@github.com:gruntwork-io/terraform-aws-service-catalog.git//modules/mgmt/openvpn-server"

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

  shared_account_id = local.common_vars.locals.account_ids.shared
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# This defines the parameters that are common across all environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  name          = "vpn"
  vpc_id        = dependency.vpc.outputs.vpc_id
  subnet_ids    = dependency.vpc.outputs.public_subnet_ids
  instance_type = "t3.micro"
  ami           = ""
  ami_filters = {
    owners = [local.common_vars.locals.account_ids.shared]
    filters = [
      {
        name   = "name"
        values = ["openvpn-server-v0.90.2-*"]
      },
    ]
  }

  # The VPN should provide a route to the VPC CIDR.
  vpn_route_cidr_blocks = [dependency.vpc.outputs.vpc_cidr_block]

  # Access to the VPN should be limited to specific, known CIDR blocks.
  allow_vpn_from_cidr_list = local.common_vars.locals.vpn_ip_allow_list
  allow_ssh_from_cidr_list = local.common_vars.locals.ssh_ip_allow_list

  # Access the VPN server over SSH using ssh-grunt.
  # See: https://github.com/gruntwork-io/terraform-aws-security/blob/master/modules/ssh-grunt
  enable_ssh_grunt                    = true
  ssh_grunt_iam_group                 = local.common_vars.locals.ssh_grunt_users_group
  ssh_grunt_iam_group_sudo            = local.common_vars.locals.ssh_grunt_sudo_users_group
  external_account_ssh_grunt_role_arn = local.common_vars.locals.allow_ssh_grunt_role

  alarms_sns_topic_arn = [dependency.sns.outputs.topic_arn]

  backup_bucket_name = "${local.name_prefix}-${lower(local.account_name)}-openvpn-backup"

  ca_cert_fields = local.common_vars.locals.ca_cert_fields

  keypair_name = "openvpn-admin-v1"

  create_route53_entry = true
  # The primary domain name for the environment - the openvpn server will prepend "vpn." to this
  # domain name and create a route 53 A record in the correct hosted zone so that the vpn server is
  # publicly addressable
  base_domain_name = local.account_vars.locals.domain_name.name

  # Flip force_destroy to true prior to destroying this module.
  force_destroy = false
}