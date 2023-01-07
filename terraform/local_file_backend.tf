resource "local_file" "foo" {
  content = templatefile(
    "${path.module}/templates/backend.tf.tftpl",
    {
      bucket = aws_s3_bucket.codepipeline_operation_artifacts.id
    }
  )
  filename = "${path.module}/../generated/backend.tf"
}
