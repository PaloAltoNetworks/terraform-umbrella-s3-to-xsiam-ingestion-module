# Build AWS Infrastructure for Cortex XSIAM/XDR Ingestion of Umbrella Logs

This Terraform module builds all the AWS infrastructure/components required to facilitate the ingestion of Cisco Umbrella logs into Palo Alto Networks Cortex XSIAM and XDR.

Umbrella can be configured to store logs in an S3 bucket, and Cortex XSIAM/XDR can be configured to ingest logs from an S3 bucket. This module creates an S3 bucket for this purpose, as well as creating the other components required such as an IAM role, SQS queue, etc

This module also creates two sets of user credentials, which can be provided to other tooling which requires access to the Umbrella logs.

Reference Links:
- https://cortex.marketplace.pan.dev/marketplace/details/Ciscoumbrellacloudsecurity/
- https://docs-cortex.paloaltonetworks.com/r/Cortex-XSIAM/Cortex-XSIAM-Administrator-Guide/Ingest-Generic-Logs-from-Amazon-S3
 -https://docs-cortex.paloaltonetworks.com/r/Cortex-XSIAM/Cortex-XSIAM-Administrator-Guide/Create-an-Assumed-Role
- https://docs.umbrella.com/umbrella-user-guide/docs/enable-logging-to-your-own-s3-bucket


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.70 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.70 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_access_key.user1_access_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_access_key.user2_access_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_policy.xsiam_umbrella_access_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.xsiam-umbrella_assume-role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.xsiam-umbrella_assume-role_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.xsiam_umbrella_access_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_user.user1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user.user2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_s3_bucket.audit_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.xsiam_umbrella](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_logging.bucket_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_notification.xsiam_umbrella](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_policy.audit_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.xsiam_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_sqs_queue.xsiam_umbrella](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.xsiam_umbrella_deadletter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.xsiam_umbrella](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_sqs_queue_redrive_allow_policy.xsiam_umbrella](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_redrive_allow_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.audit_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.xsiam-umbrella_assume-role_trust_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.xsiam_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.xsiam_umbrella](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.xsiam_umbrella_access_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | A name used for the S3 bucket where Umbrella logs will be stored | `string` | n/a | yes |
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | The external ID used for IAM role trust relationship | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | A unique project name, used for tagging and naming AWS resources | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region in which resources will be deployed | `string` | n/a | yes |
| <a name="input_umbrella_aws_account_id"></a> [umbrella\_aws\_account\_id](#input\_umbrella\_aws\_account\_id) | The AWS account ID for Umbrella; the account used to write Umbrella logs to S3 | `string` | `"568526795995"` | no |
| <a name="input_xsiam_aws_account_id"></a> [xsiam\_aws\_account\_id](#input\_xsiam\_aws\_account\_id) | The AWS account ID for XSIAM; the account used to read Umbrella logs from S3 | `string` | `"006742885340"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_assumed_role_arn"></a> [assumed\_role\_arn](#output\_assumed\_role\_arn) | ARN for the AWS Assumed Role |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the S3 Bucket |
| <a name="output_external_id"></a> [external\_id](#output\_external\_id) | External ID for the AWS Assumed Role |
| <a name="output_sqs_queue_url"></a> [sqs\_queue\_url](#output\_sqs\_queue\_url) | URL for the SQS Queue |
| <a name="output_user1_access_key"></a> [user1\_access\_key](#output\_user1\_access\_key) | Access key for first user, if required |
| <a name="output_user1_secret_key"></a> [user1\_secret\_key](#output\_user1\_secret\_key) | Secret key for first user, if required |
| <a name="output_user2_access_key"></a> [user2\_access\_key](#output\_user2\_access\_key) | Access key for second user, if required |
| <a name="output_user2_secret_key"></a> [user2\_secret\_key](#output\_user2\_secret\_key) | Secret key for second user, if required |
<!-- END_TF_DOCS -->
