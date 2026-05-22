

  create or replace view `ecommerce-ai-analytics`.`ecommerce_ai_stg`.`stg_ticket_extractions`
  OPTIONS()
  as 

WITH source AS (

    SELECT
        CAST(run_id AS INT64) AS run_id,
        CAST(ticket_id AS INT64) AS ticket_id,

        NULLIF(LOWER(TRIM(issue_type)), '') AS issue_type_raw,
        NULLIF(LOWER(TRIM(priority)), '') AS priority_raw,
        NULLIF(LOWER(TRIM(refund_risk)), '') AS refund_risk_raw,
        NULLIF(LOWER(TRIM(root_cause)), '') AS root_cause_raw,
        NULLIF(LOWER(TRIM(sentiment)), '') AS sentiment_raw,
        SAFE_CAST(confidence_score AS FLOAT64) AS confidence_score,

        LOWER(TRIM(status)) AS extraction_status,
        error_message,
        extraction_model,
        SAFE_CAST(extracted_at AS TIMESTAMP) AS extracted_at

    FROM `ecommerce-ai-analytics`.`ecommerce_ai_raw`.`raw_ticket_extraction_attempts`

),

successful_extractions AS (

    SELECT
        *
    FROM source
    WHERE extraction_status = 'success'

),

deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ticket_id
            ORDER BY extracted_at DESC
        ) AS row_num
    FROM successful_extractions
)

SELECT
    ticket_id,
    issue_type_raw AS issue_type,
    priority_raw AS priority,
    refund_risk_raw AS refund_risk,
    root_cause_raw AS root_cause,
    sentiment_raw AS sentiment,
    confidence_score,
    run_id,
    extraction_model,
    extracted_at,
    CASE
        WHEN confidence_score < 0.70 THEN TRUE
        ELSE FALSE
    END AS requires_human_review

FROM deduplicated
WHERE row_num = 1;

