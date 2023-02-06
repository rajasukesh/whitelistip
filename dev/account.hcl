# Set account-wide variables
locals {
  account_name = "dev"
  account_role = "dev"
  domain_name = {
    name = "fdc-dev.com"
    properties = {
      created_outside_terraform = true
    }
  }
}
