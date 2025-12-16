locals {
  role_name   = var.use_suffixes ? "${var.base_name}${var.role_suffix}" : var.base_name
  policy_name = var.use_suffixes ? "${var.base_name}${var.policy_suffix}" : "${var.base_name}-policy"
  group_name  = var.use_suffixes ? "${var.base_name}${var.group_suffix}" : "${var.base_name}-group"
  user_name   = var.use_suffixes ? "${var.base_name}${var.user_suffix}" : "${var.base_name}-user"

  default_tags = {
    Terraform = "true"
    ManagedBy = "terraform"
  }

  merged_tags = merge(local.default_tags, var.tags)
}


data "aws_caller_identity" "current" {}

# trivy:ignore:AVD-AWS-0086 Account root principal is intentional for assumable role pattern
# checkov:skip=CKV_AWS_356:Account root principal is intentional for assumable role pattern
data "aws_iam_policy_document" "assume_role_trust" {
  statement {
    sid     = "AllowSameAccountAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "assumable_role" {
  name               = local.role_name
  path               = var.path
  assume_role_policy = data.aws_iam_policy_document.assume_role_trust.json

  tags = local.merged_tags

  lifecycle {
    postcondition {
      condition     = startswith(self.arn, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role")
      error_message = "Role ARN does not match expected account ID pattern."
    }
    postcondition {
      condition     = self.path == var.path
      error_message = "Role path '${self.path}' does not match expected path '${var.path}'."
    }
  }
}

data "aws_iam_policy_document" "assume_role_permissions" {
  statement {
    sid       = "AllowAssumeRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.assumable_role.arn]
  }
}

resource "aws_iam_policy" "assume_role_policy" {
  name        = local.policy_name
  path        = var.path
  description = "Policy allowing sts:AssumeRole on ${aws_iam_role.assumable_role.name}"
  policy      = data.aws_iam_policy_document.assume_role_permissions.json

  tags = local.merged_tags

  lifecycle {
    postcondition {
      condition     = can(jsondecode(self.policy))
      error_message = "Policy document is not valid JSON."
    }
    postcondition {
      condition     = contains(keys(jsondecode(self.policy)), "Statement")
      error_message = "Policy document missing required 'Statement' key."
    }
  }
}

resource "aws_iam_group" "role_assumers" {
  name = local.group_name
  path = var.path
}

resource "aws_iam_group_policy_attachment" "policy_to_group" {
  group      = aws_iam_group.role_assumers.name
  policy_arn = aws_iam_policy.assume_role_policy.arn
}

resource "aws_iam_user" "service_user" {
  count = var.create_user ? 1 : 0

  name = local.user_name
  path = var.path

  tags = local.merged_tags
}

resource "aws_iam_user_group_membership" "user_to_group" {
  count = var.create_user ? 1 : 0

  user   = aws_iam_user.service_user[0].name
  groups = [aws_iam_group.role_assumers.name]
}

# Check blocks for continuous validation (soft fail - warnings only)
check "role_arn_format" {
  assert {
    condition     = can(regex("^arn:aws:iam::\\d{12}:role/.+$", aws_iam_role.assumable_role.arn))
    error_message = "Role ARN does not match expected IAM role ARN format."
  }
}

check "policy_arn_format" {
  assert {
    condition     = can(regex("^arn:aws:iam::\\d{12}:policy/.+$", aws_iam_policy.assume_role_policy.arn))
    error_message = "Policy ARN does not match expected IAM policy ARN format."
  }
}

check "role_policy_relationship" {
  assert {
    condition     = strcontains(aws_iam_policy.assume_role_policy.description, aws_iam_role.assumable_role.name)
    error_message = "Policy description should reference the role name for traceability."
  }
}
