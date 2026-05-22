from openai import OpenAI
from pydantic import BaseModel, Field, conlist
from dotenv import load_dotenv, find_dotenv
import instructor
from typing import Optional, Literal
import pandas as pd
from google.cloud import bigquery
import os
from pathlib import Path
import uuid


load_dotenv(find_dotenv(), override=True)

api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("OPENAI_API_KEY is missing")
bq_client = bigquery.Client.from_service_account_json('ecommerce-ai-analytics-4c2eb4a76634.json')
RUN_ID = str(uuid.uuid4())
BATCH_SIZE = 10
MODEL = "gpt-5.4-mini"
PROJECT_ID = "ecommerce-ai-analytics"
RAW_DATASET_ID = "ecommerce_ai_raw"
STG_DATASET_ID = "ecommerce_ai_stg"
TABLE_ID = "raw_support_tickets"
BACKUP_DIR = Path("llm_ticket_extraction_backups")

parameters = [
    "issue_type",
    "priority",
    "refund_risk",
    "root_cause",
    "sentiment",
    "confidence_score"
]

confidence_score: float = Field(
    ge=0.0,
    le=1.0,
    description="Model confidence from 0 to 1."
)

class Ticket_Extraction(BaseModel):
    issue_type: Optional[Literal[
        "delivery_delay",
        "tracking_issue",
        "damaged_package",
        "missing_item",
        "wrong_item",
        "wrong_size",
        "poor_quality",
        "not_as_described",
        "return_request",
        "refund_request",
        "payment_issue",
        "customer_service",
        "cancellation_request",
        "other"
    ]] = Field(description="Type of issue reported in the support ticket.")
    priority: Optional[Literal["low", "medium", "high"]] = Field(description="Classify urgency/severity. "
            "high = customer cannot use order/service, urgent deadline, angry/escalated tone, repeated failure, refund/legal/chargeback threat; "
            "medium = meaningful issue requiring support action, but no severe urgency; "
            "low = minor question, status check, simple clarification, no clear harm."
            )
    refund_risk: Optional[Literal["low", "medium", "high"]] = Field(description="Classify refund risk. "
            "high = explicit refund/return/cancellation request, missing item, wrong item, damaged item, poor quality, not as described, long delivery delay, or strong dissatisfaction. "
            "medium = some indication of dissatisfaction or issue, but no explicit refund request or severe problem. "
            "low = simple tracking/status request, general question, mild issue with no refund-like signal."
            )
    root_cause: Optional[Literal[
        "logistics", 
        "product_quality", 
        "sizing", 
        "payment", 
        "warehouse_error", 
        "support_process", 
        "unclear"
        ]] = Field(description="Identify the underlying cause of the issue.")
    sentiment: Optional[Literal["positive", "neutral", "negative"]] = Field(description="Customer sentiment expressed in the ticket." \
    "positive = customer is satisfied with their order, speaks positively about how the order was handled, or says they will order again. " \
    "neutral = neither negative nor positive comments about the order. No complaints and nothing indicating strong satisfaction. " \
    "negative = negative tone, unsatisfied with their order, or statements indicating the customer's negative sentiment.")
    confidence_score: float = Field(
        ge=0.0,
        le=1.0,
        description="Model confidence from 0 to 1."
    )
    
def extract_ticket_info(client, parameters, tickets, model=MODEL):
    system_prompt = f"""
    You are and expert in extracting information from customers ticket discriptions. 
    Based on given text you will recognize and exteract information about support tickets.
    
    Classify each ticket into:
    - issue_type
    - priority
    - refund_risk
    - confidence_score
    - root_cause 
    - sentiment

    Choose "other" for issue_type only if no listed category fits.
    Choose "unclear" for root cause only if no listed category fits.
    Return only the structured object.

    Priority rules:
    - high: urgent deadline, customer can't' use the product, missing/wrong/damaged item, refund threat, chargeback threat, angry/escalated tone.
    - medium: real support issue requiring action, but no strong urgency or escalation.
    - low: simple question, basic tracking/status check, no clear customer harm.

    Refund risk rules:
    - high: explicit refund/return/cancellation request, missing item, wrong item, damaged item, poor quality, not as described, long delivery delay, or strong dissatisfaction.
    - medium: some indication of dissatisfaction or issue, but no explicit refund request or severe problem. Examples include delivery delay without strong dissatisfaction, minor quality issue, or vague dissatisfaction.
    - low: simple tracking/status request, general question, mild issue with no refund-like signal.

    Sentiment rules:
    - positive: customer is satisfied with their order, speaks positively about how the order was handled, or says they will order again.
    - neutral: neither negative nor positive comments about the order. No complaints and nothing indicating strong satisfaction.
    - negative: negative tone, unsatisfied with their order, or statements indicating the customer's negative sentiment.
    """
    question = f"""
    Find information about this parameters: {parameters} based on given support tickets: {tickets}
    """
    
    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": question}
        ],
        response_model=Ticket_Extraction
    )
    
    return response

def fetch_unprocessed_tickets_from_bq(limit: int = 50) -> list[dict]:
    query = f"""
        SELECT
            r.ticket_id,
            r.ticket_text
        FROM `{PROJECT_ID}.{RAW_DATASET_ID}.raw_support_tickets` AS r
        WHERE r.ticket_id IS NOT NULL
          AND r.ticket_text IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM `{PROJECT_ID}.{RAW_DATASET_ID}.raw_ticket_extraction_attempts` AS e
              WHERE e.ticket_id = r.ticket_id
                AND e.status = 'success'
          )
        ORDER BY r.ticket_id
        LIMIT {limit}
    """

    rows = bq_client.query(query).result()

    return [
        {
            "ticket_id": row["ticket_id"],
            "ticket_text": row["ticket_text"],
        }
        for row in rows
    ]
    
def append_rows_to_bigquery(rows: list[dict]) -> None:
    if not rows:
        return

    table_id = f"{PROJECT_ID}.{RAW_DATASET_ID}.raw_ticket_extraction_attempts"

    errors = bq_client.insert_rows_json(table_id, rows)

    if errors:
        raise RuntimeError(f"BigQuery insert failed: {errors}")

    print(f"Inserted {len(rows)} rows into {table_id}")

def main() -> None:
    tickets = fetch_unprocessed_tickets_from_bq(limit=50)

    client = OpenAI(api_key=api_key)
    client = instructor.patch(client, mode=instructor.Mode.MD_JSON)

    buffer = []

    for ticket in tickets:
        try:
            response = extract_ticket_info(
                client=client,
                parameters=parameters,
                tickets=ticket["ticket_text"],
                model=MODEL,
            )

            row = response.model_dump()
            row.update({
                "run_id": RUN_ID,
                "ticket_id": ticket["ticket_id"],
                "extraction_model": MODEL,
                "status": "success",
                "error_message": None,
                "extracted_at": pd.Timestamp.now().isoformat(),
            })

        except Exception as e:
            row = {
                "run_id": RUN_ID,
                "ticket_id": ticket["ticket_id"],
                "extraction_model": MODEL,
                "issue_type": None,
                "priority": None,
                "refund_risk": None,
                "root_cause": None,
                "sentiment": None,
                "confidence_score": None,
                "status": "failed",
                "error_message": str(e)[:1000],
                "extracted_at": pd.Timestamp.now().isoformat(),
            }

        buffer.append(row)

        if len(buffer) >= BATCH_SIZE:
            append_rows_to_bigquery(buffer)
            buffer = []

    if buffer:
        append_rows_to_bigquery(buffer)

if __name__ == "__main__":
    main()
    