variable "aws_region" {
  description = "AWS region for resources."
  type        = string
  default     = "us-east-1"
}

variable "base_name" {
  description = "Base name for all IAM resources. Will be combined with suffixes to create resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-_]*$", var.base_name))
    error_message = "The base_name must start with a letter and contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "create_user" {
  description = "Whether to create an IAM user and add it to the group."
  type        = bool
  default     = false
}

variable "use_suffixes" {
  description = "Whether to append resource-type suffixes to the base_name."
  type        = bool
  default     = true
}

variable "role_suffix" {
  description = "Suffix to append to base_name for the IAM role."
  type        = string
  default     = "-role"
}

variable "policy_suffix" {
  description = "Suffix to append to base_name for the IAM policy."
  type        = string
  default     = "-assume-role-policy"
}

variable "group_suffix" {
  description = "Suffix to append to base_name for the IAM group."
  type        = string
  default     = "-group"
}

variable "user_suffix" {
  description = "Suffix to append to base_name for the IAM user."
  type        = string
  default     = "-user"
}

variable "path" {
  description = "Path for all IAM resources."
  type        = string
  default     = "/"

  validation {
    condition     = can(regex("^/.*/$", var.path)) || var.path == "/"
    error_message = "The path must begin and end with a forward slash (/), or be exactly '/'."
  }
}

variable "tags" {
  description = "Additional tags to apply to all taggable resources."
  type        = map(string)
  default     = {}
}
