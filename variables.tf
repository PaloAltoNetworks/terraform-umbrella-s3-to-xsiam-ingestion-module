variable "region" {
  description = "The AWS region in which resources will be deployed"
  type        = string
}

variable "project_name" {
  description = "A unique project name, used for tagging and naming AWS resources"
  type        = string
}

variable "bucket_name" {
  description = "A name used for the S3 bucket where Umbrella logs will be stored"
  type        = string
}

variable "umbrella_aws_account_id" {
  description = "The AWS account ID for Umbrella; the account used to write Umbrella logs to S3"
  type        = string
  default     = "568526795995"
}

variable "xsiam_aws_account_id" {
  description = "The AWS account ID for XSIAM; the account used to read Umbrella logs from S3"
  type        = string
  default     = "006742885340"
}

variable "external_id" {
  description = "The external ID used for IAM role trust relationship"
  type        = string
}
