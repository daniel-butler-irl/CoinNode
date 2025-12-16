# IAM Assumable Role

Terraform configuration for creating IAM resources that allow identities in the same AWS account to assume a role.

## Resources Created

- **IAM Role**: Assumable role with same-account trust policy (no attached policies)
- **IAM Policy**: Grants `sts:AssumeRole` permission on the created role
- **IAM Group**: Group with the assume-role policy attached
- **IAM User** (optional): User added to the group when `create_user = true`

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- [Go](https://go.dev/dl/) >= 1.21 (for tests)
- AWS credentials with IAM permissions

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"  # pragma: allowlist secret
```

## Quick Start

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

<!-- BEGIN_TF_DOCS -->
## Usage

```hcl
# Configure variables in terraform.tfvars
base_name   = "my-application"
create_user = false

tags = {
  Project     = "my-project"
  Environment = "dev"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | 5.100.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| base\_name | Base name for all IAM resources. Will be combined with suffixes to create resource names. | `string` | n/a | yes |
| aws\_region | AWS region for resources. | `string` | `"us-east-1"` | no |
| create\_user | Whether to create an IAM user and add it to the group. | `bool` | `false` | no |
| group\_suffix | Suffix to append to base\_name for the IAM group. | `string` | `"-group"` | no |
| path | Path for all IAM resources. | `string` | `"/"` | no |
| policy\_suffix | Suffix to append to base\_name for the IAM policy. | `string` | `"-assume-role-policy"` | no |
| role\_suffix | Suffix to append to base\_name for the IAM role. | `string` | `"-role"` | no |
| tags | Additional tags to apply to all taggable resources. | `map(string)` | `{}` | no |
| use\_suffixes | Whether to append resource-type suffixes to the base\_name. | `bool` | `true` | no |
| user\_suffix | Suffix to append to base\_name for the IAM user. | `string` | `"-user"` | no |

## Outputs

| Name | Description |
|------|-------------|
| group\_arn | ARN of the IAM group. |
| group\_name | Name of the IAM group. |
| policy\_arn | ARN of the IAM policy. |
| policy\_name | Name of the IAM policy. |
| role\_arn | ARN of the IAM role. |
| role\_name | Name of the IAM role. |
| user\_arn | ARN of the IAM user. Null if create\_user is false. |
| user\_name | Name of the IAM user. Null if create\_user is false. |

## Testing

This configuration includes Terratest-based Go tests for provisioning and idempotency validation.

```bash
cd terraform/test
go test -v -timeout 30m
```
<!-- END_TF_DOCS -->
