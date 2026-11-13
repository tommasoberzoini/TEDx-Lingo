import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, collect_list, regexp_replace, struct
from awsglue.dynamicframe import DynamicFrame

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# --- VARIABILI CONFIGURATE ---
S3_BUCKET_RAW = "s3://unibg-tedx-lingo-data-tbgg-raw-v2/"
S3_BUCKET_TRANSCRIPTS = "s3://unibg-tedx-lingo-data-tbgg-transcripts-v2/"
NOME_CONNESSIONE_GLUE = "Mongodbatlas connection"
# -----------------------------

# LETTURA E PULIZIA FILE GREZZI CON GESTIONE VIRGOLETTE
final_list = spark.read \
    .option("header", "true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .csv(S3_BUCKET_RAW + "final_list.csv")

related_videos = spark.read.option("header", "true").csv(S3_BUCKET_RAW + "related_videos.csv")

details = spark.read \
    .option("header", "true") \
    .option("quote", "\"") \
    .option("escape", "\"") \
    .option("multiLine", "true") \
    .csv(S3_BUCKET_RAW + "details.csv")
   
details = details.withColumn("description", regexp_replace(col("description"), "\n", " "))

trascrizioni = spark.read.option("header", "true").csv(S3_BUCKET_TRANSCRIPTS + "trascrizioni (1).csv")
# Lettura del file trascrizioni dal bucket dedicato
trascrizioni = spark.read.option("header", "true").csv(S3_BUCKET_TRANSCRIPTS + "trascrizioni (1).csv")

# TASK A: WATCH NEXT (Scarto link rotti e aggregazione)
slug_id_map = final_list.select(col("slug").alias("slug_lookup"), col("id").alias("correct_id"))

resolved_videos = related_videos.join(
    slug_id_map,
    related_videos.slug == slug_id_map.slug_lookup,
    "inner"
)

related_agg = resolved_videos.groupBy(col("id").alias("main_talk_id")).agg(
    collect_list(
        struct(col("correct_id").alias("related_id"), col("slug"), col("title"))
    ).alias("watch_next")
)

# TASK B: TRASCRIZIONI (Aggregazione timestamp e frasi)
transcript_agg = trascrizioni.groupBy(col("id").alias("tr_id")).agg(
    collect_list(
        struct(col("timestamp"), col("sentence"))
    ).alias("transcript_info")
)

# JOIN FINALE
final_dataset = final_list.join(details, "id", "left") \
    .join(related_agg, final_list.id == related_agg.main_talk_id, "left") \
    .join(transcript_agg, final_list.id == transcript_agg.tr_id, "left") \
    .drop("main_talk_id", "tr_id")

# Filtro: mantieni solo i video che hanno effettivamente il testo
final_dataset = final_dataset.filter("transcript_info is not null")

# Rinomina 'id' in '_id' per MongoDB
final_dataset = final_dataset.withColumnRenamed("id", "_id")

# SCRITTURA SU MONGODB ATLAS
dynamic_frame = DynamicFrame.fromDF(final_dataset, glueContext, "dynamic_frame")

write_mongo_options = {
    "connectionName": NOME_CONNESSIONE_GLUE,
    "database": "unibg_tedx_lingo",
    "collection": "talks",
    "ssl": "true",
    "ssl.domain_match": "false"
}

glueContext.write_dynamic_frame.from_options(
    frame=dynamic_frame,
    connection_type="mongodb",
    connection_options=write_mongo_options
)

job.commit()