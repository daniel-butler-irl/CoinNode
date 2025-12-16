output "role_arn" {
  description = "ARN of the IAM role."
  value       = aws_iam_role.assumable_role.arn
}

output "role_name" {
  description = "Name of the IAM role."
  value       = aws_iam_role.assumable_role.name
}

output "policy_arn" {
  description = "ARN of the IAM policy."
  value       = aws_iam_policy.assume_role_policy.arn
}

output "policy_name" {
  description = "Name of the IAM policy."
  value       = aws_iam_policy.assume_role_policy.name
}

output "group_arn" {
  description = "ARN of the IAM group."
  value       = aws_iam_group.role_assumers.arn
}

output "group_name" {
  description = "Name of the IAM group."
  value       = aws_iam_group.role_assumers.name
}

output "user_arn" {
  description = "ARN of the IAM user. Null if create_user is false."
  value       = var.create_user ? aws_iam_user.service_user[0].arn : null
}

output "user_name" {
  description = "Name of the IAM user. Null if create_user is false."
  value       = var.create_user ? aws_iam_user.service_user[0].name : null
}
