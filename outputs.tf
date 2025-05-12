output "sqs_queue_url" {
  description = "URL for the SQS Queue"
  value       = aws_sqs_queue.xsiam_umbrella.url
}

output "external_id" {
  description = "External ID for AWS Assumed Role"
  value       = var.external_id
}

output "assumed_role_arn" {
  description = "ARN for the AWS Assumed Role"
  value       = aws_iam_role.xsiam-umbrella_assume-role.arn
}

output "bucket_name" {
  description = "Name of S3 Bucket"
  value       = var.bucket_name
}

output "user1_access_key" {
  value       = aws_iam_access_key.user1_access_key.id
  sensitive   = true
  description = "Access key for first user, if required"
}

output "user1_secret_key" {
  value       = aws_iam_access_key.user1_access_key.secret
  sensitive   = true
  description = "Secret key for first user, if required"
}

output "user2_access_key" {
  value       = aws_iam_access_key.user2_access_key.id
  sensitive   = true
  description = "Access key for second user, if required"
}

output "user2_secret_key" {
  value       = aws_iam_access_key.user2_access_key.secret
  sensitive   = true
<<<<<<< HEAD
      ==
  des   description = "Secret key for second user, if required"
=====cription = "Secret key for second user, if required"
>>>>>>> 55a1cab3754e227d9d0f4f05608ee152195dede8
}
