terraform {
  backend "s3" {
    bucket = "codepipeline-operation-artifacts-20230107125411634900000002"
    key    = "operation/terraform.tfstate"
    region = "eu-central-1"
  }
}
