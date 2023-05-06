resource "aws_s3_bucket" "homelab_openstack_production_terraform_state" {
  bucket_prefix = "homelab-production-tf-state-"
}

resource "aws_s3_bucket_public_access_block" "homelab_openstack_production_terraform_state" {
  bucket = aws_s3_bucket.homelab_openstack_production_terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "homelab_openstack_production_terraform_state" {
  bucket = aws_s3_bucket.homelab_openstack_production_terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "homelab_openstack_production_terraform_state_lock" {
  name         = "homelab-production-tf-state-lock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_iam_user" "homelab_openstack_production_terraform" {
  name = "homelab-openstack-production-terraform"
}

resource "aws_iam_access_key" "homelab_openstack_production_terraform" {
  user = aws_iam_user.homelab_openstack_production_terraform.name
}

data "aws_iam_policy_document" "homelab_openstack_production_terraform" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.homelab_openstack_production_terraform_state.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.homelab_openstack_production_terraform_state.arn}/production.tfstate"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]

    resources = [
      aws_dynamodb_table.homelab_openstack_production_terraform_state_lock.arn
    ]
  }
}

resource "aws_iam_policy" "homelab_openstack_production_terraform" {
  name   = "homelab_openstack_production_terraform"
  policy = data.aws_iam_policy_document.homelab_openstack_production_terraform.json
}

resource "aws_iam_user_policy_attachment" "homelab_openstack_production_terraform" {
  user       = aws_iam_user.homelab_openstack_production_terraform.name
  policy_arn = aws_iam_policy.homelab_openstack_production_terraform.arn
}

output "homelab_openstack_production_terraform_user" {
  value = {
    access_key_id     = aws_iam_access_key.homelab_openstack_production_terraform.id
    secret_access_key = aws_iam_access_key.homelab_openstack_production_terraform.secret
  }

  sensitive = true
}

resource "aws_secretsmanager_secret" "homelab_openstack_production_terraform" {
  name = "homelab_openstack_production_terraform"
}

resource "aws_secretsmanager_secret_version" "homelab_openstack_production_terraform" {
  secret_id = aws_secretsmanager_secret.homelab_openstack_production_terraform.id

  secret_string = jsonencode({
    s3_bucket         = aws_s3_bucket.homelab_openstack_production_terraform_state.id
    dynamodb_table    = aws_dynamodb_table.homelab_openstack_production_terraform_state_lock.name
    access_key_id     = aws_iam_access_key.homelab_openstack_production_terraform.id
    secret_access_key = aws_iam_access_key.homelab_openstack_production_terraform.secret
  })
}

## sns for homelab production notifications
resource "aws_sns_topic" "homelab_openstack_production_monitoring_notifications" {
  name = "homelab_openstack_production_monitoring_notifications"
}

resource "aws_sns_topic_subscription" "homelab_openstack_production_monitoring_notifications_jasper" {
  protocol  = "email"
  endpoint  = "jasper.z@posteo.de"
  topic_arn = aws_sns_topic.homelab_openstack_production_monitoring_notifications.arn
}

resource "aws_iam_user" "homelab_openstack_production_monitoring_notifications" {
  name = "homelab_openstack_production_monitoring_notifications"
}

resource "aws_iam_access_key" "homelab_openstack_production_monitoring_notifications" {
  user = aws_iam_user.homelab_openstack_production_monitoring_notifications.name
}

data "aws_iam_policy_document" "homelab_openstack_production_monitoring_notifications" {
  statement {
    effect = "Allow"

    actions = [
      "sns:Publish",
      "sns:GetTopicAttributes"
    ]

    resources = [
      aws_sns_topic.homelab_openstack_production_monitoring_notifications.arn
    ]
  }
}

resource "aws_iam_policy" "homelab_openstack_production_monitoring_notifications" {
  name   = "homelab_openstack_production_monitoring_notifications"
  policy = data.aws_iam_policy_document.homelab_openstack_production_monitoring_notifications.json
}

resource "aws_iam_user_policy_attachment" "homelab_openstack_production_monitoring_notifications" {
  user       = aws_iam_user.homelab_openstack_production_monitoring_notifications.name
  policy_arn = aws_iam_policy.homelab_openstack_production_monitoring_notifications.arn
}

resource "aws_secretsmanager_secret" "homelab_openstack_production_monitoring_notifications" {
  name = "homelab_openstack_production_monitoring_notifications"
}

resource "aws_secretsmanager_secret_version" "homelab_openstack_production_monitoring_notifications" {
  secret_id = aws_secretsmanager_secret.homelab_openstack_production_monitoring_notifications.id

  secret_string = jsonencode({
    topic_arn         = aws_sns_topic.homelab_openstack_production_monitoring_notifications.arn
    access_key_id     = aws_iam_access_key.homelab_openstack_production_monitoring_notifications.id
    secret_access_key = aws_iam_access_key.homelab_openstack_production_monitoring_notifications.secret
  })
}
