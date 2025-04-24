#---------------------------------------------------------------------------------------------------
# IAM Policy
# See below for permissions necessary to run Terraform.
# https://www.terraform.io/docs/backends/types/s3.html#example-configuration
#
# terragrunt users would also need additional permissions.
# https://github.com/nozaq/terraform-aws-remote-state-s3-backend/issues/74
#---------------------------------------------------------------------------------------------------

################################################################################
# Locals – assemble the policy in parts
################################################################################
locals {
  # statements that are always needed
  iam_policy_base = [
    {
      Effect   = "Allow"
      Action   = ["s3:ListBucket", "s3:GetBucketVersioning"]
      Resource = aws_s3_bucket.state.arn
    },
    {
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = "${aws_s3_bucket.state.arn}/*"
    },
    {
      Effect   = "Allow"
      Action   = ["kms:ListKeys"]
      Resource = "*"
    },
    {
      Effect = "Allow"
      Action = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey"
      ]
      Resource = aws_kms_key.this.arn
    }
  ]

  # only present when the lock table is created
  iam_policy_dynamodb = var.enable_dynamodb_lock ? [
    {
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ]
      Resource = aws_dynamodb_table.lock[0].arn
    }
  ] : []
}

################################################################################
# IAM Policy
################################################################################
resource "aws_iam_policy" "terraform" {
  count = var.terraform_iam_policy_create ? 1 : 0

  name_prefix = var.override_terraform_iam_policy_name ? null : var.terraform_iam_policy_name_prefix
  name        = var.override_terraform_iam_policy_name ? var.terraform_iam_policy_name : null

  # Build the final document as valid JSON
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = concat(local.iam_policy_base, local.iam_policy_dynamodb)
  })

  tags = var.tags
}
