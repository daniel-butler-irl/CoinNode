# Prompts

> in the terraform directory I want to use the AWS provider to create forur IAM resoures that share a consistent name with suffixes optional/toggleable. role (no policies) assumable by identities in the same account policiy allowing sts:AssumeRole on that role. group  with the policy attached and user added to the group. use terraform and aws provider version constraints; inputs for base name, path, tags. output ARNs and names. and use reasonable defaults tagging and minimal privaleges. use terratest to provision and test for idempotency.

**AI PLAN**
 IAM Assumable Role Terraform Implementation Plan

 Overview

 Create IAM resources directly in terraform/ directory with four resources (role, policy, group, optional
 user), consistent naming with configurable suffixes, and Terratest coverage.

 No submodule needed - Terratest runs directly against terraform/.

 File Structure

 terraform/
 ├── provider.tf          # AWS provider configuration
 ├── versions.tf          # Provider/Terraform constraints
 ├── variables.tf         # Input variables
 ├── locals.tf            # Naming and tag logic
 ├── iam.tf               # IAM resource definitions
 ├── outputs.tf           # Output definitions
 └── test/
     ├── go.mod
     └── iam_test.go

 Implementation Steps

 Step 1: Create Core Files

 versions.tf
 - Terraform >= 1.5
 - AWS Provider ~> 5.0

 provider.tf
 - AWS provider with region variable

 variables.tf
 | Variable      | Type        | Default               | Description                 |
 |---------------|-------------|-----------------------|-----------------------------|
 | aws_region    | string      | "us-east-1"           | AWS region                  |
 | base_name     | string      | required              | Base name for all resources |
 | create_user   | bool        | false                 | Toggle user creation        |
 | use_suffixes  | bool        | true                  | Toggle suffix appending     |
 | role_suffix   | string      | "-role"               | Role name suffix            |
 | policy_suffix | string      | "-assume-role-policy" | Policy suffix               |
 | group_suffix  | string      | "-group"              | Group suffix                |
 | user_suffix   | string      | "-user"               | User suffix                 |
 | path          | string      | "/"                   | IAM path for resources      |
 | tags          | map(string) | {}                    | Additional tags             |

 locals.tf
 - Compute resource names: base_name + suffix (when use_suffixes = true)
 - Default tags: Terraform=true, ManagedBy=terraform
 - Merge default + user tags

 iam.tf
 1. data.aws_caller_identity.current - Get account ID
 2. data.aws_iam_policy_document.assume_role_trust - Trust policy for same-account
 3. aws_iam_role.this - Role with trust policy, no attached policies
 4. data.aws_iam_policy_document.assume_role - Policy allowing sts:AssumeRole on role ARN
 5. aws_iam_policy.this - Managed policy from document
 6. aws_iam_group.this - Group
 7. aws_iam_group_policy_attachment.this - Attach policy to group
 8. aws_iam_user.this (count = create_user ? 1 : 0) - Optional user
 9. aws_iam_user_group_membership.this - Add user to group

 outputs.tf
 - role_arn, role_name
 - policy_arn, policy_name
 - group_arn, group_name
 - user_arn, user_name (null if not created)

 Step 2: Create Terratest Tests

 test/go.mod
 - Go 1.21+
 - terratest v0.46.x
 - testify for assertions

 test/iam_test.go
 | Test Function      | Purpose                                      |
 |--------------------|----------------------------------------------|
 | TestIAMBasic       | Deploy without user, validate ARNs           |
 | TestIAMWithUser    | Deploy with user, validate user ARN          |
 | TestIAMIdempotency | ApplyAndIdempotent - apply twice, no changes |

 Step 3: Validate

 - Run terraform fmt -recursive
 - Run terraform validate
 - Run pre-commit hooks (tflint, trivy, checkov)

 Security Design

 - Minimal privileges: Policy only grants sts:AssumeRole on the specific role
 - Same-account trust: Trust policy uses arn:aws:iam::${account_id}:root
 - No inline policies: Role created without attached policies

 Files to Create

 1. terraform/versions.tf
 2. terraform/provider.tf
 3. terraform/variables.tf
 4. terraform/locals.tf
 5. terraform/iam.tf
 6. terraform/outputs.tf
 7. terraform/test/go.mod
 8. terraform/test/iam_test.go
