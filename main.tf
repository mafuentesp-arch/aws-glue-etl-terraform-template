locals {
  bucket_name = "${var.project_name}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

resource "aws_s3_bucket" "etl" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_public_access_block" "etl" {
  bucket = aws_s3_bucket.etl.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "etl" {
  bucket = aws_s3_bucket.etl.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "raw_csv" {
  bucket = aws_s3_bucket.etl.id
  key    = "raw/sales_transactions_raw.csv"
  source = "${path.module}/data/sales_transactions_raw.csv"
  etag   = filemd5("${path.module}/data/sales_transactions_raw.csv")
}

resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.etl.id
  key    = "scripts/glue_sales_etl.py"
  source = "${path.module}/glue/glue_sales_etl.py"
  etag   = filemd5("${path.module}/glue/glue_sales_etl.py")
}

