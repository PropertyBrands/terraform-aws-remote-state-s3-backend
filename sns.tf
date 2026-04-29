#---------------------------------------------------------------------------------------------------
# Replication failure SNS topic
#---------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "replication_failure_sns" {
  count = local.replication_failure_notification_enabled ? 1 : 0

  statement {
    sid    = "AllowS3PublishReplicationEvents"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sns:Publish"]

    resources = [aws_sns_topic.replication_failure[0].arn]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.state.arn]
    }
  }
}

resource "aws_sns_topic" "replication_failure" {
  count = local.replication_failure_notification_enabled ? 1 : 0

  name_prefix = "tf-remote-state-repl-failure-"
  tags        = var.tags
}

resource "aws_sns_topic_policy" "replication_failure" {
  count = local.replication_failure_notification_enabled ? 1 : 0

  arn    = aws_sns_topic.replication_failure[0].arn
  policy = data.aws_iam_policy_document.replication_failure_sns[0].json
}

resource "aws_sns_topic_subscription" "replication_failure" {
  count = local.replication_failure_notification_enabled ? 1 : 0

  topic_arn = aws_sns_topic.replication_failure[0].arn
  protocol  = "email"
  endpoint  = var.replication_failure_notification_email
}
