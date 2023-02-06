# Set account-wide variables
locals {
  account_name = "stage"
  account_role = "stage"
  domain_name = {
    name = "fc-stage.com"
    properties = {
      created_outside_terraform = true
    }
  }
}
