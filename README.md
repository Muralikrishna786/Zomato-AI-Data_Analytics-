# Zomato-AI-Data_Analytics-
Zomato AI Data Analytics Platform

A complete end-to-end data engineering and AI analytics project built around Zomato-style restaurant, customer, food, order, and review data.

The project demonstrates:

AWS S3-based raw data storage

Snowflake data warehousing

dbt transformations and data modeling

Apache Airflow orchestration using Docker

OpenAI-powered review enrichment

AI-ready dbt models

Streamlit RAG / Text-to-SQL analytics

SQL generation from natural-language questions

Production-style separation of RAW, STAGING, and analytical layers

1. Project Overview

The platform takes raw Zomato data files, loads them into Snowflake, transforms them using dbt, enriches customer reviews using OpenAI, and provides an AI interface through Streamlit.

High-level workflow

                         ┌─────────────────────┐
                         │       AWS S3        │
                         │   Raw Zomato Files  │
                         └──────────┬──────────┘
                                    │
                                    │ COPY INTO
                                    ▼
                         ┌─────────────────────┐
                         │      Snowflake      │
                         │      RAW Layer      │
                         └──────────┬──────────┘
                                    │
                                    │ dbt
                                    ▼
                         ┌─────────────────────┐
                         │      dbt Models     │
                         │ STAGING / DIM / FCT │
                         │      / MARTS        │
                         └──────────┬──────────┘
                                    │
                       ┌────────────┴────────────┐
                       │                         │
                       ▼                         ▼
              ┌─────────────────┐      ┌──────────────────┐
              │ OpenAI Review   │      │ Analytical dbt   │
              │ Enrichment      │      │ / AI Models      │
              └────────┬────────┘      └────────┬─────────┘
                       │                         │
                       └────────────┬────────────┘
                                    ▼
                         ┌─────────────────────┐
                         │ Streamlit AI App    │
                         │ RAG / Text-to-SQL   │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         Natural Language Query

2. Main Technologies

Technology

Purpose

Python

Data processing and AI integration

AWS S3

Raw data storage

Snowflake

Cloud data warehouse

dbt

Data transformation and modeling

Apache Airflow

Workflow orchestration

Docker

Containerized Airflow environment

OpenAI API

Review enrichment and natural-language SQL

Streamlit

Interactive analytics UI

SQL

Data loading, transformation, and analytics

Git/GitHub

Version control

3. Project Structure

Zomato-AI-Data_Analytics/
│
├── AI/
│   ├── .env
│   ├── enrich_reviews.py
│   ├── rag_chat.py
│   └── text_to_sql.py
│
├── airflow/
│   ├── docker-compose.yml
│   └── dags/
│       └── zomato_batch.py
│
├── zomato/
│   ├── dbt_project.yml
│   ├── models/
│   │   ├── staging/
│   │   ├── dimensions/
│   │   ├── facts/
│   │   └── marts/
│   ├── snapshots/
│   ├── seeds/
│   └── macros/
│
└── README.md

The exact dbt subdirectories may vary depending on the current project files. The important architectural layers are RAW → STAGING → analytical models/marts → AI.

4. Data Architecture

RAW Layer

Raw files are stored in AWS S3 and loaded into Snowflake RAW tables.

Current RAW entities include:

ZOMATO.RAW.restaurants
ZOMATO.RAW.users
ZOMATO.RAW.food
ZOMATO.RAW.menu
ZOMATO.RAW.orders
ZOMATO.RAW.order_items
ZOMATO.RAW.reviews

The S3 stage used by the Airflow DAG is:

@ZOMATO.RAW.ZOMATO_RAW_STAGE

Files are organized by folders:

restaurants/
users/
food/
menu/
orders/
order_items/
reviews/

5. Snowflake

Database

ZOMATO

Warehouse

ZOMATO_WH

dbt Role

DBT_ROLE

Main schemas

The project uses a layered warehouse approach.

ZOMATO
│
├── RAW
│   ├── restaurants
│   ├── users
│   ├── food
│   ├── menu
│   ├── orders
│   ├── order_items
│   └── reviews
│
├── STAGING
│   └── Cleaned / standardized dbt models
│
└── Analytical schemas
    ├── Dimensions
    ├── Facts
    └── Marts

The exact final analytical schema depends on the dbt model configuration in the project.

6. AWS S3 to Snowflake

The Airflow DAG executes Snowflake COPY INTO statements.

Example:

COPY INTO ZOMATO.RAW.restaurants
FROM @ZOMATO.RAW.ZOMATO_RAW_STAGE/restaurants/
ON_ERROR='CONTINUE';

The same approach is used for:

restaurants
users
food
menu
orders
order_items
reviews

This provides automated ingestion from S3 into Snowflake.

7. dbt Transformation Layer

dbt is responsible for transforming raw Snowflake data into clean analytical models.

The dbt project is located inside the repository at:

zomato/

Inside Docker, the project is mounted at:

/opt/airflow/dbt/zomato

The dbt executable is:

/opt/airflow/dbt_venv/bin/dbt

The dbt profiles directory is:

/opt/airflow/profiles

dbt commands

Check dbt configuration

docker compose exec scheduler /opt/airflow/dbt_venv/bin/dbt debug `
  --project-dir /opt/airflow/dbt/zomato `
  --profiles-dir /opt/airflow/profiles

Expected result:

All checks passed!

Build core models

docker compose exec scheduler /opt/airflow/dbt_venv/bin/dbt build `
  --project-dir /opt/airflow/dbt/zomato `
  --profiles-dir /opt/airflow/profiles `
  --exclude tag:ai

Build AI models

docker compose exec scheduler /opt/airflow/dbt_venv/bin/dbt build `
  --select tag:ai `
  --project-dir /opt/airflow/dbt/zomato `
  --profiles-dir /opt/airflow/profiles

Build everything

docker compose exec scheduler /opt/airflow/dbt_venv/bin/dbt build `
  --project-dir /opt/airflow/dbt/zomato `
  --profiles-dir /opt/airflow/profiles

8. dbt Lineage

The project uses dbt model dependencies through ref().

For example:

SELECT *
FROM {{ ref('stg_food') }}

ref() should be used when referencing another dbt model.

Do not use:

{{ source('stg_food', 'food') }}

for a dbt model.

source() is intended for external/raw source definitions declared in sources.yml.

A typical lineage is:

RAW
 │
 ├── restaurants ──> stg_restaurants ──> dim_restaurants
 │
 ├── users ────────> stg_users ────────> dim_customer
 │
 ├── food ──────────> stg_food ─────────> dim_food
 │
 ├── orders ────────> stg_orders ───────> fct_orders
 │
 ├── order_items ───> stg_order_items ──> analytical models
 │
 └── reviews ───────> stg_reviews ──────> AI enrichment

9. Apache Airflow

Airflow orchestrates the complete batch pipeline.

Airflow runs inside Docker.

The main DAG is:

airflow/dags/zomato_batch.py

DAG ID:

zomato_batch

Schedule:

@daily

Catchup:

False

10. Airflow Pipeline

The DAG contains four major tasks:

reload_raw
     │
     ▼
dbt_build_core
     │
     ▼
enrich_reviews
     │
     ▼
dbt_build_ai

Task 1 — reload_raw

Loads raw S3 data into Snowflake.

Operator:

SQLExecuteQueryOperator

Connection:

snowflake_default

Task 2 — dbt_build_core

Runs the main dbt models while excluding AI-tagged models.

Command:

dbt build --exclude tag:ai

Task 3 — enrich_reviews

Runs:

/opt/airflow/ai/enrich_reviews.py

This Python script sends review information to OpenAI and stores enriched results in Snowflake.

Task 4 — dbt_build_ai

Runs only dbt models tagged with:

ai

Command:

dbt build --select tag:ai

11. Airflow DAG Code

The core DAG pattern is:

reload_raw >> dbt_build_core >> enrich_reviews >> dbt_build_ai

This ensures that:

Raw data is loaded first.

Core dbt models are built next.

Reviews are enriched using OpenAI.

AI dbt models are built last.

12. Docker

The Airflow environment is containerized using Docker Compose.

Main services include:

airflow-apiserver
airflow-dag-processor
airflow-postgres
airflow-scheduler

Start Airflow

From the airflow directory:

cd "C:\Education\Data Analytics\Data Engineering\Zomato-AI-Data_Analytics\airflow"

Start containers:

docker compose up -d

Check containers:

docker compose ps

Stop containers:

docker compose down

Restart:

docker compose down
docker compose up -d

13. Airflow UI

Open:

http://localhost:8080

Find the DAG:

zomato_batch

From the Airflow UI you can:

Enable/disable the DAG

Trigger a DAG run

View task status

View logs

Inspect task dependencies

Monitor failures

14. OpenAI Review Enrichment

The project uses OpenAI to enrich Zomato reviews.

The enrichment process analyzes reviews and generates structured information such as:

sentiment
sentiment_score
topic
key_issue

Example conceptual output:

Review:
"The food was good but delivery was late."

Sentiment:
negative

Sentiment Score:
-0.7

Topic:
delivery

Key Issue:
Late delivery

The enrichment script is:

AI/enrich_reviews.py

Inside Docker:

/opt/airflow/ai/enrich_reviews.py

15. Running Review Enrichment Locally

Activate the project virtual environment if required:

.\.venv\Scripts\Activate.ps1

Install dependencies:

python -m pip install openai python-dotenv

Run:

python AI\enrich_reviews.py

If the script is executed from the AI directory:

python enrich_reviews.py

16. Environment Variables

Secrets should never be hard-coded into source code or committed to Git.

Typical environment variables include:

OPENAI_API_KEY
SNOWFLAKE_ACCOUNT
SNOWFLAKE_USER
SNOWFLAKE_PASSWORD

Keep .env files out of version control.

Example .gitignore:

.env
*.env
__pycache__/
*.pyc
.venv/
target/
logs/

Important

If the .env file is located under:

AI/.env

while Docker Compose is located under:

airflow/docker-compose.yml

Docker Compose will not automatically use AI/.env as its default environment file.

One option is to run Compose with:

docker compose --env-file ..\AI\.env up -d

Alternatively, maintain the Compose environment file in the airflow directory.

Never commit API keys or passwords to GitHub.

17. Streamlit AI Application

The project contains Streamlit applications for AI-based analytics.

Main files:

AI/rag_chat.py
AI/text_to_sql.py

RAG Chat

Run:

python -m streamlit run rag_chat.py

Text-to-SQL

Run:

python -m streamlit run text_to_sql.py

The default Streamlit URL is:

http://localhost:8501

18. Natural Language to SQL

The Text-to-SQL workflow allows a user to ask questions in English.

Example:

Which city has the highest average delivery time?

The AI generates SQL similar to:

SELECT
    city,
    AVG(delivery_time_min) AS average_delivery_time
FROM <database>.<schema>.<table>
WHERE is_delivered = TRUE
GROUP BY city
ORDER BY average_delivery_time DESC
LIMIT 100;

The generated SQL is then executed against Snowflake.

The application returns the result to the user.

19. Important Table Naming Rule for AI SQL

AI-generated SQL must use the actual Snowflake object names and schemas.

For example:

ZOMATO.STAGING.FCT_ORDERS

is different from:

FCT_ORDERS

If an unqualified table produces:

Object 'FCT_ORDERS' does not exist or not authorized

check the actual table location.

Use:

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM ZOMATO.INFORMATION_SCHEMA.TABLES
WHERE UPPER(TABLE_NAME) = 'FCT_ORDERS';

You can also check multiple analytical objects:

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM ZOMATO.INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN (
    'FCT_ORDERS',
    'FACT_ORDERS',
    'DIM_FOOD',
    'DIM_RESTAURANTS',
    'DIM_CUSTOMER'
)
ORDER BY TABLE_SCHEMA, TABLE_NAME;

The Streamlit application should use the actual fully qualified table names where appropriate.

20. RAG / AI Analytics Architecture

Conceptually:

User Question
     │
     ▼
Streamlit UI
     │
     ▼
OpenAI
     │
     ├── Understand question
     │
     └── Generate SQL
     │
     ▼
Snowflake
     │
     ▼
Query Result
     │
     ▼
Streamlit
     │
     ▼
User

For a RAG-style workflow, relevant schema/data context is supplied to the language model so that the generated answer is grounded in the available Zomato data.

21. Useful Snowflake Queries

Check RAW tables

SHOW TABLES IN SCHEMA ZOMATO.RAW;

Check all tables

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM ZOMATO.INFORMATION_SCHEMA.TABLES
ORDER BY TABLE_SCHEMA, TABLE_NAME;

Check order-related tables

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM ZOMATO.INFORMATION_SCHEMA.TABLES
WHERE UPPER(TABLE_NAME) LIKE '%ORDER%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

Check reviews

SELECT *
FROM ZOMATO.RAW.REVIEWS
LIMIT 10;

22. dbt Documentation

Generate dbt documentation:

docker compose exec scheduler /opt/airflow/dbt_venv/bin/dbt docs generate `
  --project-dir /opt/airflow/dbt/zomato `
  --profiles-dir /opt/airflow/profiles

The dbt documentation provides:

Model descriptions

Column information

Dependencies

Source-to-model lineage

Model metadata

The lineage should show relationships between raw sources, staging models, dimensions, facts, marts, and AI models.

23. Troubleshooting

Problem: Could not find profile named 'zomato'

Incorrect:

--profiles-dir /opt/airflow/dbt/zomato

Correct:

--profiles-dir /opt/airflow/profiles

Test:

docker compose exec scheduler /opt/airflow/dbt_venv/bin/dbt debug `
  --project-dir /opt/airflow/dbt/zomato `
  --profiles-dir /opt/airflow/profiles

Problem: Airflow is using an old DAG

Restart:

docker compose down
docker compose up -d

Verify the DAG inside the scheduler:

docker compose exec scheduler grep -n "profiles-dir" /opt/airflow/dags/zomato_batch.py

Both dbt tasks should reference:

/opt/airflow/profiles

Problem: OpenAI API key is not set

Warning:

The "OPENAI_API_KEY" variable is not set.
Defaulting to a blank string.

Check safely without displaying the secret:

docker compose exec scheduler bash -c 'if [ -n "$OPENAI_API_KEY" ]; then echo "OPENAI_API_KEY is SET"; else echo "OPENAI_API_KEY is NOT SET"; fi'

Make sure the environment file is supplied to Docker Compose.

Problem: Streamlit ScriptRunContext warnings

Do not run:

python rag_chat.py

Use:

python -m streamlit run rag_chat.py

For Text-to-SQL:

python -m streamlit run text_to_sql.py

Problem: Streamlit port already in use

Default port:

8501

Stop the existing Streamlit process or use another port:

python -m streamlit run rag_chat.py --server.port 8502

Problem: Docker daemon unavailable

If Docker reports an error connecting to the Docker Desktop engine, make sure Docker Desktop is running.

Then test:

docker version

and:

docker compose ps

24. Recommended Startup Sequence

For a fresh development session:

Step 1 — Start Docker Desktop

Make sure Docker Desktop is running.

Step 2 — Open the Airflow directory

cd "C:\Education\Data Analytics\Data Engineering\Zomato-AI-Data_Analytics\airflow"

Step 3 — Start Airflow

docker compose up -d

Step 4 — Check containers

docker compose ps

Step 5 — Test dbt

docker compose exec scheduler /opt/airflow/dbt_venv/bin/dbt debug `
  --project-dir /opt/airflow/dbt/zomato `
  --profiles-dir /opt/airflow/profiles

Step 6 — Open Airflow

http://localhost:8080

Step 7 — Trigger zomato_batch

The pipeline runs:

S3 → Snowflake RAW
       ↓
   dbt Core
       ↓
OpenAI Enrichment
       ↓
   dbt AI

Step 8 — Start Streamlit

From the AI directory:

cd ..\AI
python -m streamlit run rag_chat.py

Open:

http://localhost:8501

25. Development Workflow

A typical development workflow is:

1. Add / update source data
          ↓
2. Upload raw files to S3
          ↓
3. Load data into Snowflake RAW
          ↓
4. Develop dbt staging models
          ↓
5. Develop dimensions / facts / marts
          ↓
6. Test with dbt
          ↓
7. Enrich reviews with OpenAI
          ↓
8. Build AI dbt models
          ↓
9. Test Text-to-SQL / RAG
          ↓
10. Orchestrate with Airflow
          ↓
11. Monitor pipeline

26. Validation Checklist

Before considering the pipeline successful, verify:

AWS

S3 bucket exists

Required folders exist

Raw files are uploaded

Snowflake external stage can access S3

Snowflake

ZOMATO database exists

ZOMATO_WH warehouse exists

DBT_ROLE exists and has required permissions

RAW tables exist

Data is loaded successfully

dbt

dbt debug passes

Staging models build

Dimension models build

Fact models build

Mart models build

AI models build

ref() is used correctly

dbt lineage is generated correctly

Airflow

Docker containers are running

zomato_batch appears in Airflow

reload_raw succeeds

dbt_build_core succeeds

enrich_reviews succeeds

dbt_build_ai succeeds

OpenAI

API key is configured

Review enrichment runs successfully

Enriched results are stored in Snowflake

Streamlit

Application starts

Snowflake connection works

Natural-language questions are accepted

Generated SQL uses valid table/schema names

Query results are displayed

27. Security

Never commit credentials.

Do not put values such as:

OPENAI_API_KEY
SNOWFLAKE_PASSWORD
AWS_SECRET_ACCESS_KEY

directly into:

Python source code

dbt project files

Git repositories

README files

screenshots

public GitHub repositories

Use environment variables or a secure secrets manager.

If a secret has accidentally been exposed, revoke/rotate it immediately.

28. Future Improvements

Potential production enhancements include:

Incremental dbt models

dbt tests for data quality

Source freshness checks

Snowflake tasks/streams where appropriate

Airflow retry policies

Airflow alerting

Centralized secret management

AWS IAM roles instead of static credentials

Better OpenAI prompt validation

SQL safety validation before execution

Query result caching

RAG with vector embeddings

Metadata/catalog integration

CI/CD using GitHub Actions

Automated dbt documentation deployment

Data quality monitoring

Dashboarding with Power BI/Tableau

Role-based access control

Production logging and observability

29. Project Outcome

This project demonstrates a complete modern data and AI pipeline:

                  ZOMATO DATA
                      │
                      ▼
                   AWS S3
                      │
                      ▼
              Snowflake RAW
                      │
                      ▼
                    dbt
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
     Analytics Models       Review Enrichment
          │                       │
          │                     OpenAI
          │                       │
          └───────────┬───────────┘
                      ▼
                  AI Models
                      │
                      ▼
               Streamlit App
                      │
                      ▼
             Natural Language
                 Analytics

The result is an end-to-end platform that combines data engineering, cloud warehousing, transformation, orchestration, generative AI, and natural-language analytics in one project.

30. Author

Murali Krishna

Project: Zomato AI Data Analytics

Technologies: Python · AWS S3 · Snowflake · dbt · Apache Airflow · Docker · OpenAI · Streamlit
