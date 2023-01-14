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
  name           = "homelab-production-tf-state-lock"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

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
