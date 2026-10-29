import sys
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.window import Window

args = getResolvedOptions(
    sys.argv,
    ["JOB_NAME", "SOURCE_PATH", "TARGET_PATH", "REJECTED_PATH"],
)

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session
job = Job(glue_context)
job.init(args["JOB_NAME"], args)

source = (
    spark.read.option("header", "true")
    .option("inferSchema", "false")
    .csv(args["SOURCE_PATH"])
    .withColumn("source_file", F.input_file_name())
    .withColumn("row_order", F.monotonically_increasing_id())
)

normalized = (
    source
    .withColumn("transaction_id_num", F.expr("try_cast(transaction_id AS BIGINT)"))
    .withColumn("transaction_date_parsed", F.expr("try_cast(transaction_date AS DATE)"))
    .withColumn("total_amount_num", F.expr("try_cast(total_amount AS DECIMAL(12,2))"))
    .withColumn(
        "status_normalized",
        F.when(F.lower("status").isin("completed", "complete"), F.lit("Completed"))
        .when(F.lower("status") == "pending", F.lit("Pending"))
        .when(F.lower("status").isin("cancelled", "cancel"), F.lit("Cancelled")),
    )
)

duplicate_window = Window.partitionBy("transaction_id_num").orderBy("row_order")
classified = (
    normalized
    .withColumn("duplicate_rank", F.row_number().over(duplicate_window))
    .withColumn(
        "error_reason",
        F.when(F.col("duplicate_rank") > 1, F.lit("DUPLICATE"))
        .when(F.col("customer_id").isNull() | (F.trim("customer_id") == ""), F.lit("MISSING_CUSTOMER"))
        .when(F.col("total_amount_num").isNull() | (F.col("total_amount_num") <= 0), F.lit("INVALID_AMOUNT"))
        .when(F.col("status_normalized").isNull(), F.lit("INVALID_STATUS"))
        .when(F.col("transaction_date_parsed").isNull(), F.lit("INVALID_DATE"))
        .otherwise(F.lit("VALID")),
    )
)

valid = (
    classified.filter(F.col("error_reason") == "VALID")
    .select(
        F.col("transaction_id_num").alias("transaction_id"),
        "customer_id",
        F.col("transaction_date_parsed").alias("transaction_date"),
        F.col("status_normalized").alias("status"),
        F.col("total_amount_num").alias("total_amount"),
        "region",
        "source_system",
        "source_file",
    )
    .withColumn("transaction_year", F.year("transaction_date"))
    .withColumn("transaction_month", F.month("transaction_date"))
    .withColumn("load_timestamp", F.current_timestamp())
)

rejected = classified.filter(F.col("error_reason") != "VALID").drop("row_order")

valid.write.mode("overwrite").partitionBy("region", "transaction_year").parquet(args["TARGET_PATH"])
rejected.write.mode("overwrite").partitionBy("error_reason").parquet(args["REJECTED_PATH"])

print(f"SOURCE_ROWS={source.count()}")
print(f"VALID_ROWS={valid.count()}")
print(f"REJECTED_AND_DUPLICATE_ROWS={rejected.count()}")

job.commit()

