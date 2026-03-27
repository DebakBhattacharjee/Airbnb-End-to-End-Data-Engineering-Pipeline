Airbnb End-to-End Data Engineering Pipeline
An end-to-end data engineering project built on Snowflake, dbt, and AWS. The pipeline ingests raw Airbnb data from S3, transforms it through a medallion architecture, and produces a dimensional model with full SCD Type-2 history tracking.

Architecture
S3 (raw CSV files)
        |
        | COPY INTO via Snowflake External Stage (IAM)
        v
Snowflake Staging Schema (raw tables)
        |
        v
Bronze Layer  — views, 1:1 mirror of staging, no transformation
        |
        v
Silver Layer  — incremental models, type casting, deduplication, upsert via merge
        |
        v
OBT (One Big Table) — all silver tables joined into a single wide table
        |
        v
Ephemeral Models — column shaping per dimension, no physical warehouse object
        |
        v
dbt Snapshots (SCD Type-2) — dim_bookings, dim_listings, dim_hosts in gold schema
        |
        v
Fact Table — final gold table, references snapshot dimensions

Tech Stack
LayerToolCloud StorageAWS S3Data WarehouseSnowflakeTransformationdbt Core 1.11Adapterdbt-snowflakeAuthAWS IAM + Snowflake Storage IntegrationVersion ControlGit

Project Structure
aws_dbt_snowflakeproject/
├── models/
│   ├── bronze/          # views over staging tables
│   ├── silver/          # incremental models with merge strategy
│   ├── gold/
│   │   ├── ephemeral/   # column-shaped CTEs for each dimension
│   │   ├── OBT.sql      # metadata-driven wide table
│   │   └── fact.sql     # final fact table
│   └── sources/         # source declarations pointing to staging schema
├── snapshots/           # SCD Type-2 configs for dim tables
├── macros/              # generate_schema_name override
├── seeds/
├── tests/
└── dbt_project.yml

Data Model
Source data: Airbnb listings, hosts, and bookings CSVs loaded into AIRBNB.STAGING.
Bronze — straight SELECT * from each staging table, materialised as views. No transformation, just lineage entry point.
Silver — three incremental models (silver_bookings, silver_listings, silver_hosts) using merge strategy with unique_key. Type casting, null handling, and deduplication happen here.
OBT — metadata-driven model. Table join config is defined as a Jinja variable (list of dicts with table, alias, columns, join condition). A Jinja loop generates the full JOIN SQL at compile time. Materialised as a table in the gold schema.
Ephemeral dims — bookings.sql, listings.sql, hosts.sql inside gold/ephemeral/. Each selects only the columns relevant to that dimension from the OBT. Materialised as ephemeral — they become CTEs inlined into whatever references them, no physical object created.
Snapshots — dbt snapshots on each ephemeral dim using timestamp strategy on CREATED_AT. Active records use 9999-12-31 as dbt_valid_to instead of NULL for cleaner BI queries. Stored in AIRBNB.GOLD.
Fact table — selects transactional columns from OBT and joins against the snapshot dimension tables.

Key dbt Patterns Used
Metadata-driven OBT
Join logic is defined as config rather than hardcoded SQL. Adding a new table to the OBT requires adding one dictionary to the config list — the macro loop handles the rest.
generate_schema_name override
Custom macro ensures models land in exact schema names (bronze, silver, gold) rather than dbt's default prefixed names (dbt_dev_bronze).
SCD Type-2 via snapshots
History is tracked at the fully-joined OBT level rather than individual silver tables, since the source data lacks reliable updated_at columns for per-entity change tracking.
Incremental merge with late-arrival handling
Silver models use incremental_strategy='merge' with a lookback window on the filter condition to handle late-arriving records.

Setup
Prerequisites

Python 3.10+
AWS account with S3 bucket
Snowflake account (free trial works)
dbt-core and dbt-snowflake installed

bashpip install dbt-core dbt-snowflake
Snowflake setup
Create the database, staging schema, and tables, then set up an external stage pointing to your S3 bucket via IAM storage integration. Load raw data:
sqlCOPY INTO AIRBNB.STAGING.LISTINGS FROM @s3_stage/listings.csv;
COPY INTO AIRBNB.STAGING.BOOKINGS FROM @s3_stage/bookings.csv;
COPY INTO AIRBNB.STAGING.HOSTS FROM @s3_stage/hosts.csv;
dbt setup
Create profiles.yml in ~/.dbt/ (do not commit this file):
yamlaws_dbt_snowflakeproject:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: your_account_identifier
      user: your_username
      password: your_password
      role: ACCOUNTADMIN
      database: AIRBNB
      schema: staging
      warehouse: COMPUTE_WH
      threads: 4
Run the pipeline
bashdbt debug          # verify connection
dbt run            # build all models
dbt snapshot       # run SCD2 snapshots
dbt test           # run data quality tests
