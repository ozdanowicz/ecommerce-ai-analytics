from pathlib import Path
import os

from dotenv import load_dotenv
from google.cloud import bigquery


def load_sql_template(sql_path: str) -> str:
    path = Path(sql_path)

    if not path.exists():
        raise FileNotFoundError(f"SQL file not found: {path}")

    return path.read_text(encoding="utf-8")


def render_sql(sql: str, project_id: str, raw_dataset: str) -> str:
    return (
        sql
        .replace("{{ project_id }}", project_id)
        .replace("{{ raw_dataset }}", raw_dataset)
    )


def run_bigquery_sql(sql: str, project_id: str, location: str) -> None:
    client = bigquery.Client(project=project_id)

    print("Running BigQuery job...")
    query_job = client.query(sql, location=location)
    query_job.result()

    print(f"BigQuery job finished successfully.")
    print(f"Job ID: {query_job.job_id}")


def main() -> None:
    load_dotenv()

    project_id = os.getenv("GCP_PROJECT_ID")
    raw_dataset = os.getenv("BQ_RAW_DATASET", "ecommerce_ai_raw")
    location = os.getenv("BQ_LOCATION", "US")
    sql_path = os.getenv(
        "SUPPORT_TICKETS_SQL_PATH",
        "sql/02_create_raw_support_tickets.sql"
    )

    if not project_id:
        raise ValueError("Missing GCP_PROJECT_ID in .env")

    sql_template = load_sql_template(sql_path)
    sql = render_sql(
        sql=sql_template,
        project_id=project_id,
        raw_dataset=raw_dataset
    )

    run_bigquery_sql(
        sql=sql,
        project_id=project_id,
        location=location
    )


if __name__ == "__main__":
    main()