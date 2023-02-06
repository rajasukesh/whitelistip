# Set account-wide variables
locals {
  account_name = "prod"
  account_role = "prod"
  domain_name = {
    name = "fdc-prod.com"
    properties = {
      created_outside_terraform = true
    }
  }
}
