CREATE TABLE IF NOT EXISTS `{{ project_id }}.{{ raw_dataset }}.raw_ticket_extraction_attempts` (
   run_id STRING,
  ticket_id INT64,
  extraction_model STRING,

  issue_type STRING,
  priority STRING,
  refund_risk STRING,
  root_cause STRING,
  sentiment STRING,
  confidence_score FLOAT64,
  
  status STRING,
  error_message STRING,
  extracted_at TIMESTAMP
)
PARTITION BY DATE(extracted_at)
CLUSTER BY ticket_id, extraction_version, status;