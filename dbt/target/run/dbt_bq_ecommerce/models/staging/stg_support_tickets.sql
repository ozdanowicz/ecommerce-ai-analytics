

  create or replace view `ecommerce-ai-analytics`.`ecommerce_ai_stg`.`stg_support_tickets`
  OPTIONS()
  as 

SELECT
    CAST(ticket_id AS INT64) AS ticket_id,
    CAST(user_id AS INT64) AS user_id,
    CAST(order_id AS INT64) AS order_id,
    CAST(created_at AS TIMESTAMP) AS created_at,
    NULLIF(LOWER(TRIM(ticket_channel)), '') AS channel,
    NULLIF(TRIM(ticket_text), '') AS ticket_description
FROM `ecommerce-ai-analytics`.`ecommerce_ai_raw`.`raw_support_tickets`;

