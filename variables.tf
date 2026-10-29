variable "aws_region" {
  description = "AWS region where the ETL infrastructure will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Lowercase prefix used for project resources and the globally unique S3 bucket"
  type        = string
  default     = "aws-etl-iac-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.project_name))
    error_message = "project_name must start with a lowercase letter and contain 3-31 lowercase letters, numbers, or hyphens."
  }
}

variable "owner" {
  description = "Owner tag applied to all supported AWS resources"
  type        = string
  default     = "Miguel-Fuentes"
}

variable "force_destroy" {
  description = "Allow Terraform to delete the S3 bucket even when it contains objects. Use true only for disposable labs."
  type        = bool
  default     = false
}

