{{ config(
    schema='ecommerce_ai_marts',
    materialized='table'
) }}

SELECT
    t.ticket_id,
    t.user_id,
    t.order_id,

    t.ticket_created_at,
    o.order_created_at AS order_created_at,

    t.sentiment,
    t.refund_risk,
    t.priority,
    t.issue_type,
    t.root_cause,
    t.requires_human_review,
    CASE t.sentiment  WHEN "negative" THEN 1 ELSE 0 END AS is_negative_sentiment,
    CASE  t.refund_risk  WHEN "high" THEN 1 ELSE 0 END AS is_high_refund_risk,
    CASE  t.priority  WHEN "high" THEN 1 ELSE 0 END AS is_high_priority,

    1 AS issue_count,
    o.order_status,
    o.total_order_revenue,
    o.total_order_margin,
    o.is_returned_order,
    o.is_cancelled_order,
    o.order_created_at
FROM {{ ref('int_ticket_enriched_orders') }} t
LEFT JOIN {{ ref('int_order_revenue') }} o 
ON o.order_id = t.order_id
