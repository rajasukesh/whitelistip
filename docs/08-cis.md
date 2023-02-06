# CIS AWS Foundations Benchmark Support

This Reference Architecture is compatible with the [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services/), which is "an objective, consensus-driven security guideline" for securing AWS accounts. Every Gruntwork Reference Architecture is designed from the bottom up with security in mind, but the CIS-compliant reference architecture meets the specific criteria laid out by the CIS Benchmark. This section reviews some of the differences and constraints that you'll encounter in this environment.

We'll cover the following:

* [Manual steps](#manual-steps)
* [Admin access](#admin-access)
* [Remote server administration restrictions](#remote-server-administration-restrictions)
* [Security Hub caveats](#security-hub-caveats)

For a deep dive on the Benchmark, we strongly recommend that you review the Gruntwork guide on [How to achieve compliance with the CIS AWS Foundations Benchmark](https://gruntwork.io/guides/compliance/how-to-achieve-cis-benchmark-compliance/). We'll link to specific sections within the guide throughout this document.

## Manual steps

We've automated as much of the Benchmark as possible, but a few steps must be completed manually. To achieve full compliance, complete the [manual steps](https://gruntwork.io/guides/compliance/how-to-achieve-cis-benchmark-compliance/#manual_steps) outlined in the guide.

## Admin access

Recommendation 1.16 of the Benchmark disallows the use of full administrator privileges in any AWS account. That is, no user can have `*:*` IAM permissions. However, you'll undoubtedly need administrative access from time-to-time, and it's a best practice (as well as a CIS Benchmark recommendation) to avoid the use of the root account.

To handle this, we've created a group in the security account called `iam-admins`, and we've added your IAM Users to this group. The `iam-admins` group has an IAM Policy attached with `iam:*` permissions. In other words, that user can perform any IAM operation, including modifying any IAM Policy, thus granting _effective_ but not _explicit_ administrator access.

To work with AWS on a day-to-day basis, we suggest either or both of the following options:

1. Use the existing `developers` group with fine-grained permissions.
1. Add new groups and roles using the `custom-iam-entity` module.

### The `developers` group

The reference architecture includes a group called `developers` that can be granted a set of fine-grainted IAM permissions. You can customize these permissions and add users to this group for day-to-day usage.

1. In `security/_global/account-baseline/terragrunt.hcl`, add a new list input called `dev_permitted_services`. For example, you could set `dev_permitted_services = ["s3", "ec2:Describe*"]` to grant full access to S3 as well as access to all of the EC2 `Describe` APIs.
1. In `security/_global/account-baseline/users.yml`, add any users that should have these permissions to the `developers` group.
1. Apply the changes by invoking the CI/CD pipeline as outlined in the [Gruntwork Pipelines docs](04-configure-gw-pipelines.md).

Refer to the [`dev_permitted_services` variable description`](https://github.com/gruntwork-io/terraform-aws-security/blob/23a1ba0ce065f18f368bed6e172023671c0995cd/modules/iam-policies/variables.tf#L29) for additional information.

### The `custom-iam-entity` module

The `terraform-aws-security` repository includes the [`custom-iam-entity` module](https://github.com/gruntwork-io/terraform-aws-security/tree/master/modules/custom-iam-entity). You can use this module to add new IAM Roles and groups with any set of permissions that you need.

To use this effectively in the reference architecture, you should:

1. Add an IAM Role in each account with the desired permissions, with a policy that allows the security account to assume the role.
1. Add an IAM Group in the security account with permissions to assume the role.

You can repeat the process for as many roles and groups as you need.

#### Add a new IAM Role in each account

In each account where you want to grant permissions, you can create an IAM Role with access to the desired permissions.

First, create a new `terragrunt.hcl` in each account. For example, to create an IAM Role in the dev account with full permissions to EC2, create a new file called `dev/_global/ec2-access-role/terragrunt.hcl` with the contents below:

```
terraform {
  source = "git::git@github.com:gruntwork-io/terraform-aws-security.git//modules/custom-iam-entity?ref=v1.0.0" # Replace this version with the latest terraform-aws-security release!
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

locals {
  # Automatically load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # A local for more convenient access to the account_ids map.
  account_ids = local.common_vars.locals.account_ids
}

inputs = {
  # Required for CIS compliance
  should_require_mfa = true

  should_create_iam_role = true
  iam_role_name = "ec2-access-role"

  assume_role_arns = ["arn:aws:iam::${local.account_ids.security}:root"]

  iam_aws_managed_policy_names = [
    "AmazonEC2FullAccess",
  ]
}
```

Apply the configuration via the CI/CD pipeline to create the role.

Once the new role exists in the dev account, it's time to create the group in the security account. Create a new file called `security/_global/ec2-access-group/terragrunt.hcl` with the following contents:

```
terraform {
  source = "git::git@github.com:gruntwork-io/terraform-aws-security.git//modules/custom-iam-entity?ref=v1.0.0" # Replace this version with the latest terraform-aws-security release!
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

locals {
  # Automatically load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # A local for more convenient access to the account_ids map.
  account_ids = local.common_vars.locals.account_ids
}

inputs = {
  # Required for CIS compliance
  should_require_mfa = true

  should_create_iam_group = true
  iam_group_name = ".account.dev-ec2-full-access"
  iam_group_assume_role_arns = ["arn:aws:iam::${local.account_ids.dev}:role/ec2-access-role"]
}
```

After this configuration is applied, you should have:

1. A role in the dev account with the AmazonEC2FullAccess managed policy attached.
1. A group in the security account with a policy attached allowing you to assume the IAM Role in the dev account.

You can use this method to satisfy any custom permission needs you may have.

## Remote server administration restrictions

There are two Benchmark recommendations that limit access to server administration ports (such as SSH and RDP):

1. Recommendation 5.1 disallows access from the `0.0.0.0/0` CIDR block in ingress NACL (Network Access Control List) rule.
1. Recommendation 5.2 disallows access from the `0.0.0.0/0` CIDR block in a security group rule.

To satisfy these requirements, you must only connect from known CIDR ranges. If you do not have a static CIDR range, you can use a VPN service that provides one. You can connect to the VPN service and still connect to the OpenVPN server in your reference architecture at the same time. This is known as a VPN cascade.

Some services offer compatibility with cascading VPN configurations, while others do not. In addition, some services, such as [Surfshark](https://surfshark.com/), offer servers with well known IP addresses that you can add to the IP allow list. Note that these servers will also be used by other customers of the same VPN service, so if you add them to the allow list, those other customers would also be allowed at the IP layer. Of course, they wouldn't have any credentials to connect to your VPN, nor would they have any knowledge _about_ your environment, so actual risk of those other customers accessing your systems is low. Nonetheless, for the most secure configuration, you should use a service that offers a dedicated static IP address, such as [NordVPN](https://nordvpn.com/). This will incur an additional cost from the VPN provider.

During the deployment, Gruntwork increased the NACL rule quota to the maximum value of 40 rules per NACL. This is a hard limit on how many rules can exist on any given NACL. The default number of rules in a CIS-compliant deployment varies based on the region and the number of CIDR ranges provided in the allow list. Be aware that may run in to this maximum limit if you add too many CIDR ranges to the `ssh_ip_allow_list`, as described below.

### Updating the static CIDR ranges

We deployed the reference architecture with the following CIDR ranges that were provided in the initial `reference-architecture-form.yml`:

**SSH IP Allow List**
- 172.16.0.0/12


**VPN IP Allow List**
- 172.16.0.0/12
- 34.197.83.11/32


These CIDR ranges are used in the following locations:

- You'll find the full list in the `ssh_ip_allow_list` and `vpn_ip_allow_list` variables in `common.hcl` in the root of the repository.
- The `ssh_ip_allow_list` variable is used in NACL rules within the `vpc-mgmt` of each account to restrict access to ports 22 (SSH) and 3389 (RDP).
- The `ssh_ip_allow_list` variable is used in NACL rules within the app `vpc` of each account to restrict access to ports 22 (SSH) and 3389 (RDP).
- The `ssh_ip_allow_list` variable is used in NACL and security group rules within the `openvpn-server` of each account to restrict access to ports 22 (SSH), 3389 (RDP), and UDP port 1194 (OpenVPN).
- The `vpn_ip_allow_list` variable is used in security group rules within the `openvpn-server` of each account to restrict access to UDP port 1194 (OpenVPN).

To modify the list of CIDR ranges, take the following steps:

1. Update the `ssh_ip_allow_list` and/or `vpn_ip_allow_list` variables in `common.hcl`.
1. For each account and region, run `terragrunt apply` for the `vpc-mgmt` module.
1. For each account and region in which the app VPC is present (e.g. dev, stage, and prod), run `terragrunt apply` for the `vpc`module.
1. For each account and region in which a VPN is present, run `terragrunt apply` for the `openvpn-server` module.

The plan should show the expected changes to the network ACL and security group rules.

You can find more information about the features available in the VPC modules to restrict server administration in [the `Configure networking` section of the guide](https://gruntwork.io/guides/compliance/how-to-achieve-cis-benchmark-compliance/#configure_networking).

## Security Hub caveats

As part of the reference architecture we have deployed [AWS Security Hub](https://aws.amazon.com/security-hub/). Although it is not strictly a requirement of the Benchmark, it provides a convenient interface for monitoring compliance. For convenience, we have configured Security Hub to aggregate data from each account in to the Logs account. You can view the Security Hub console in us-east-1 to see data from each of the accounts. However, there are some caveats to the data you'll find there:

- The reference architecture supports cross-account configurations for many resources, such as AWS Config SNS topic notifications. Security Hub *does not support* cross-account multi-region SNS topic data retrieval, and checks related to that will appear as errors.
- This Reference Architecture is designed to comply with v1.3.0 of the CIS AWS Foundations Benchmark. We've enabled [AWS Security Hub with support for the Benchmark](https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards-cis.html). However, Security Hub only supports v1.2.0, not version 1.3.0. There are some differences and gaps in coverage, and hence the Security Hub dashboard will be slightly incorrect. We are hopeful that this will be updated in the future.

## Wrapping up

Once again, we strongly recommend that you read the Gruntwork guide on [How to achieve compliance with the CIS AWS Foundations Benchmark](https://gruntwork.io/guides/compliance/how-to-achieve-cis-benchmark-compliance/). You can also [download the Benchmark itself for free from the Center for Internet Security](https://www.cisecurity.org/cis-benchmarks/#amazon_web_services). Keep your eye on [Gruntwork's terraform-aws-cis-service-catalog repo](https://github.com/gruntwork-io/terraform-aws-cis-service-catalog/) for updates.
