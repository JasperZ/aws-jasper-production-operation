data "aws_iam_policy_document" "codepipeline_operation_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "codepipeline.amazonaws.com",
        "codebuild.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "codepipeline_operation" {
  statement {
    sid = "1"

    actions = [
      "*"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "codepipeline_operation" {
  name   = "example_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.codepipeline_operation.json
}

resource "aws_iam_role" "codepipeline_operation" {
  name                = "codepipeline_operation"
  assume_role_policy  = data.aws_iam_policy_document.codepipeline_operation_assume_role.json
  managed_policy_arns = [aws_iam_policy.codepipeline_operation.arn]
}

resource "aws_codestarconnections_connection" "github" {
  name          = "operation"
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "codepipeline_operation_artifacts" {
  bucket_prefix = "codepipeline-operation-artifacts-"

  tags = {
    Name = "codepipeline_operation_artifacts"
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_operation_artifacts" {
  bucket = aws_s3_bucket.codepipeline_operation_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_codebuild_project" "operation_terraform_plan" {
  name           = "operation_terraform_plan"
  build_timeout  = "5"
  queued_timeout = "5"

  service_role = aws_iam_role.codepipeline_operation.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:1.3.7"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "CODEPIPELINE"
    buildspec = yamlencode({
      version = "0.2"

      phases = {
        build = {
          commands = [
            "cd terraform",
            "terraform init",
            "terraform plan"
          ]
        }
      }
    })
  }
}

resource "aws_codebuild_project" "operation_terraform_apply" {
  name           = "operation_terraform_apply"
  build_timeout  = "5"
  queued_timeout = "5"

  service_role = aws_iam_role.codepipeline_operation.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:1.3.7"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "CODEPIPELINE"
    buildspec = yamlencode({
      version = "0.2"

      phases = {
        build = {
          commands = [
            "cd terraform",
            "terraform init",
            "terraform apply -auto-approve"
          ]
        }
      }
    })
  }
}

resource "aws_codepipeline" "operation" {
  name     = "operation"
  role_arn = aws_iam_role.codepipeline_operation.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_operation_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "JasperZ/aws-jasper-production-operation"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name             = "Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.operation_terraform_plan.name
      }
    }
  }

  stage {
    name = "Approve"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "Apply"

    action {
      name             = "Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.operation_terraform_apply.name
      }
    }
  }
}
