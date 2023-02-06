
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
  source = "${local.source_base_url}?ref=v0.7.0"
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
      version = "~> 4.6"
    }
  }
}
EOF
}
# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "route53" {
  config_path = "${get_terragrunt_dir()}/../../_global/route53-public"

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
  source_base_url = "git::git@github.com:Furniture-com/fdc-aws-infra-catalog.git//modules/services/sftp"

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  sftp_domain_name = "sftp.${local.account_vars.locals.domain_name.name}"

  hosted_zone_id = dependency.route53.outputs.public_hosted_zone_map[local.account_vars.locals.domain_name.name]

  user_details = [
    {
      username       = "testUser",
      public_ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCY9PKUQ67FQBsb1CuGCT/9w1aifl0AOwlwc9OxiGJPcuKNFmw6DfXpBu7+rEzeQ18dESqqULlW2sdTgCpsEjOJCmbmh7lfCOzLuJ3GbB8XLrQAsOO3zhpfaGWbIGO9Xoppqg9zoQTzTSwm6fyTY3SgDIdoJ1inkEsTIxPURE89QQON/530G6sJ6lNC5E0HU2SNYfw+mFXoYhf98He5yddl0HUIS+/8eq35y8uzFXR/zulBUgoKP6+MyUEYsWmvpFVP5oj0aTaIpQnBEaswhMeK/xjI9F55tbXcmA2YJthOL4cnWqIZOX2u0iSwcnZKPvTrleUCFrv2VkbquXQebXH2NrtGvi7VW+7umO3vGcwweX0ZzJS+GiYLNQKYzn+tctgbpN42GM/A1Qai5ahK5P9Cq1XqTiZg6Tw5sc6C3mBwHP3jzjiUKxb7j83UB59dFbdn/3VsJUhjun8qyym45lKEFMj0XCXwt47vHbpRJijjLySj2WMpizKx24w/OLGuE8E= "
    },
    {
      username       = "GWAdmin",
      public_ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCfM8/aNIOk9sxQclxdJmcCU4WnKWJHrja5AAD2SrwVQunb5gkJ10VR6ee5AYRraNfC55piPJV2npp0Ny/tRXbrZp43mHoO/BxiAqxa0mp0jBPEVcoqrmjH6jGBUsuWZFBrS+QPQYbmvG3IfQ3o8zf30GsKGLIbWEKwWm+g8C+JDkx72Bz2HLSba8mToBwEUbarkXDXIkpLrG/SBAI4rtYMs9zZUiCIlW6iP73+qsUC01XRywPr5yadm7tSmpmtA88Dr+I27g2KVPqQfW+hrWcFSzjLh8H5xplVo0jqtur1Ci8rYuXxi/Q9o3VHfU4iqYkUNOLn2TbE2Z/6l3gEPmIuvWRric21Je27onJYf42S/9mXL/0E3m7uLDmqdLc2KBFADvNJR2wrwtBMtWQO4C4cHjHZav587r/rJ3IuE3n7NniZFegMqeWwj0j91SRe1cUFWqChO2HpPz30BECmAJXtEzP0ORm7j/iv4Kc/44YQKyXPNTcXpoEmHGtvxuAYnRE= "
    },
    {
      username       = "rfAdmin",
      public_ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDTIF6u0o+EdnQO8IIC20fDbTzj5yBqrxCF7SzuQujwz75K7TrNTZgcsf/2pbio0KYRoTTfSkhmAuqNt2spvs8a6v4NmwX4I9Gvn1N3r3SLdXE1lQa7O8nQoO7eQOV5XC1woBD54ND68PLzXU5pK1drPmh+GZ8xyx6VcIetOnb9bUFsLaUkvpXjBDXwkocfFJxz4J7qjO9n5vHxf4F4e1iqKci7KegSKPaxVBwkXr3vfSrq3gHrj/YPFkv5pTe2Hnyp8LdVIkyKn26eiw0IjEq6j+KHe1Cu/wZOaCeARgUFjz2FfnnfhRmYPtD0PQ16BIThiRataaZkYBnAzxjAbySMhCVTBKu65/bLhrNaefgYUgsJtUGGLxfLvAVVQ14j6MHfNslbqKEqnZZz74OumsHGVjUHd1dftXDR1D9qZ4lnI7bF8usfEBfQSs6Nju8A/GfGMJD0bIBp8ArRQuDO0Vy1Lk7jPiUQ6N9hhOuajzQehiGnD0AJjUY5LSFAu3V5+Ws= "
    }
  ]
}
