# Set account-wide variables
locals {
  account_name = "qa"
  account_role = "qa"
  domain_name = {
    name = "fdc-qa.com"
    properties = {
      created_outside_terraform = true
    }
  }
}
