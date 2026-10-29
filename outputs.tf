output "bucket_name" {
  description = "S3 bucket created for the ETL lab"
  value       = aws_s3_bucket.etl.bucket
}

output "glue_job_name" {
  description = "Glue job to run after terraform apply"
  value       = aws_glue_job.sales_etl.name
}

output "crawler_name" {
  description = "Crawler to run after the Glue job succeeds"
  value       = aws_glue_crawler.sales.name
}

output "catalog_database" {
  description = "Glue Data Catalog database"
  value       = aws_glue_catalog_database.etl.name
}

output "athena_results_uri" {
  description = "S3 location to configure for Athena query results"
  value       = "s3://${aws_s3_bucket.etl.bucket}/athena-results/"
}

output "glue_role_arn" {
  description = "IAM role assumed by the Glue job and crawler"
  value       = aws_iam_role.glue.arn
}

