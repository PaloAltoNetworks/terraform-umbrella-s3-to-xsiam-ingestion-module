################################################################################################
################################################################################################
# Build AWS Infrastructure and Components for XSIAM Ingestion of Umbrella Logs
################################################################################################
################################################################################################

# Set AWS region
provider "aws" {
  region = var.region
}

# Set variable for our current "user"
data "aws_caller_identity" "current" {}

################################################################################################
# S3 Bucket
################################################################################################

# Create an S3 bucket for Umbrella logs
resource "aws_s3_bucket" "xsiam_umbrella" {
  bucket        = var.bucket_name
  force_destroy = true # This ensures bucket destroy also destroys bucket contents

  tags = {
    project = var.project_name
  }
}

# Create an S3 bucket for S3 "audit logs"
resource "aws_s3_bucket" "audit_logs" {
  bucket        = "${var.project_name}-audit-logs"
  force_destroy = true # This ensures bucket destroy also destroys bucket contents

  tags = {
    project = var.project_name
  }
}

# Create a bucket policy for the audit logs bucket
resource "aws_s3_bucket_policy" "audit_logs_policy" {
  bucket = aws_s3_bucket.audit_logs.id
  policy = data.aws_iam_policy_document.audit_logs_policy.json
}

data "aws_iam_policy_document" "audit_logs_policy" {
  statement {
    sid    = "AllowLogDeliveryWrite" # Add a descriptive Sid
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"] # Allow S3 logging service
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.audit_logs.arn}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["log-delivery-write"]
    }
  }
}

# Enable logging for Umbrella data bucket
resource "aws_s3_bucket_logging" "bucket_logging" {
  bucket = aws_s3_bucket.xsiam_umbrella.id

  target_bucket = aws_s3_bucket.audit_logs.id
  target_prefix = "log/"
}

# Create access policy for the S3 bucket, allowing privileges for Cisco's Umbrella AWS account
resource "aws_s3_bucket_policy" "xsiam_bucket_policy" {
  bucket = aws_s3_bucket.xsiam_umbrella.id
  policy = data.aws_iam_policy_document.xsiam_bucket_policy.json
}

data "aws_iam_policy_document" "xsiam_bucket_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.umbrella_aws_account_id}:user/logs"]
    }
    actions = [
      "s3:GetBucketLocation",
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
    ]
  }
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.umbrella_aws_account_id}:user/logs"]
    }
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
    ]
  }
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.umbrella_aws_account_id}:user/logs"]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*",
    ]
  }
  statement {
    sid    = ""
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.umbrella_aws_account_id}:user/logs"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*",
    ]
  }

  # Add read only access for two external users (Cisco staff)
  statement {
    sid    = "ReadOnlyAccessUser1"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.user1.arn]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*",
      "arn:aws:s3:::${var.bucket_name}",
    ]
  }
  statement {
    sid    = "ReadOnlyAccessUser2"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.user2.arn]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*",
      "arn:aws:s3:::${var.bucket_name}",
    ]
  }
}

# Create IAM users for read-only access
resource "aws_iam_user" "user1" {
  name = "${var.project_name}-readonly-user1"
}
resource "aws_iam_user" "user2" {
  name = "${var.project_name}-readonly-user2"
}

# Create access keys for the IAM users
resource "aws_iam_access_key" "user1_access_key" {
  user = aws_iam_user.user1.name
}
resource "aws_iam_access_key" "user2_access_key" {
  user = aws_iam_user.user2.name
}

# Create a notification to send messages to SQS when objects are created in the S3 bucket
resource "aws_s3_bucket_notification" "xsiam_umbrella" {
  bucket = aws_s3_bucket.xsiam_umbrella.id

  queue {
    queue_arn = aws_sqs_queue.xsiam_umbrella.arn
    events    = ["s3:ObjectCreated:*"]
  }
}


################################################################################################
# SQS Queue
################################################################################################

# SQS queue from which XSIAM get notified
resource "aws_sqs_queue" "xsiam_umbrella" {
  name                       = var.project_name
  visibility_timeout_seconds = 30     # AWS default in web GUI
  delay_seconds              = 0      # AWS default in web GUI
  receive_wait_time_seconds  = 0      # AWS default in web GUI
  message_retention_seconds  = 345600 # AWS default in web GUI
  max_message_size           = 262144 # In KiB. AWS default in web GUI

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.xsiam_umbrella_deadletter.arn
    maxReceiveCount     = 4
  })

  tags = {
    project = var.project_name
  }
}

# IAM policy allowing Amazon S3 service to send messages to SQS to notify of new items in S3 bucket
data "aws_iam_policy_document" "xsiam_umbrella" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["SQS:SendMessage"]
    resources = [aws_sqs_queue.xsiam_umbrella.arn]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.xsiam_umbrella.arn]
    }
  }
}

# Attach IAM policy to SQS queue
resource "aws_sqs_queue_policy" "xsiam_umbrella" {
  queue_url = aws_sqs_queue.xsiam_umbrella.id
  policy    = data.aws_iam_policy_document.xsiam_umbrella.json
}


################################################################################################
# SQS - Deadletter Queue
################################################################################################

# SQS queue for any undeliverable messages
resource "aws_sqs_queue" "xsiam_umbrella_deadletter" {
  name = "${var.project_name}-deadletter"

  tags = {
    project = var.project_name
  }
}

# Attach policy to deadletter SQS queue
resource "aws_sqs_queue_redrive_allow_policy" "xsiam_umbrella" {
  queue_url = aws_sqs_queue.xsiam_umbrella_deadletter.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.xsiam_umbrella.arn]
  })
}


################################################################################################
# XSIAM Assumed Role
################################################################################################

# IAM role which XSIAM will assume
resource "aws_iam_role" "xsiam-umbrella_assume-role" {
  name               = "${var.project_name}-assume-role"
  assume_role_policy = data.aws_iam_policy_document.xsiam-umbrella_assume-role_trust_policy.json # AKA "Trust Policy"

  tags = {
    project = var.project_name
  }
}

# IAM policy for XSIAM's AWS account to assume the IAM role, including an external ID as a required security mechanism
data "aws_iam_policy_document" "xsiam-umbrella_assume-role_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.xsiam_aws_account_id}:root"]
    }
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

# IAM policy for the IAM role which XSIAM will assume, giving access to S3 bucket and SQS queue
resource "aws_iam_policy" "xsiam_umbrella_access_policy" {
  policy = data.aws_iam_policy_document.xsiam_umbrella_access_policy.json

  tags = {
    project = var.project_name
  }
}

data "aws_iam_policy_document" "xsiam_umbrella_access_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.xsiam_umbrella.arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [
      aws_sqs_queue.xsiam_umbrella.arn,
    ]
  }
}

# Attach the specific S3/SQS permissions to the IAM role which XSIAM will assume
resource "aws_iam_role_policy_attachment" "xsiam_umbrella_access_policy_attach" {
  role       = aws_iam_role.xsiam-umbrella_assume-role.name
  policy_arn = aws_iam_policy.xsiam_umbrella_access_policy.arn
}

# Attach the AWS-predefined "SecurityAudit" permissions to the IAM role which XSIAM will assume
resource "aws_iam_role_policy_attachment" "xsiam-umbrella_assume-role_policy_attach" {
  role       = aws_iam_role.xsiam-umbrella_assume-role.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}
