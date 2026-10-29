resource "aws_glue_catalog_database" "etl" {
  name        = replace("${var.project_name}_db", "-", "_")
  description = "Data Catalog database created by Terraform for ${var.project_name}"
}

resource "aws_glue_job" "sales_etl" {
  name              = "${var.project_name}-job"
  description       = "Validates sales data and writes curated and rejected Parquet datasets"
  role_arn          = aws_iam_role.glue.arn
  glue_version      = "6.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  max_retries       = 0
  timeout           = 10

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.etl.bucket}/${aws_s3_object.glue_script.key}"
  }

  default_arguments = {
    "--SOURCE_PATH"                      = "s3://${aws_s3_bucket.etl.bucket}/raw/"
    "--TARGET_PATH"                      = "s3://${aws_s3_bucket.etl.bucket}/curated/"
    "--REJECTED_PATH"                    = "s3://${aws_s3_bucket.etl.bucket}/rejected/"
    "--job-language"                     = "python"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.glue_service,
    aws_iam_role_policy.etl_bucket_access,
    aws_s3_object.glue_script,
    aws_s3_object.raw_csv
  ]
}

resource "aws_glue_crawler" "sales" {
  name          = "${var.project_name}-crawler"
  database_name = aws_glue_catalog_database.etl.name
  role          = aws_iam_role.glue.arn
  description   = "Catalogs curated and rejected Parquet datasets"
  table_prefix  = "etl_"

  s3_target {
    path = "s3://${aws_s3_bucket.etl.bucket}/curated/"
  }

  s3_target {
    path = "s3://${aws_s3_bucket.etl.bucket}/rejected/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  depends_on = [
    aws_iam_role_policy_attachment.glue_service,
    aws_iam_role_policy.etl_bucket_access
  ]
}

