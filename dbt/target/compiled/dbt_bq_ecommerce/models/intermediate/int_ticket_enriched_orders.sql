

WITH tickets_extractions AS (
    SELECT
        *
    FROM `ecommerce-ai-analytics`.`ecommerce_ai_stg`.`stg_ticket_extractions`
),
tickets AS (
    SELECT
        *
    FROM `ecommerce-ai-analytics`.`ecommerce_ai_stg`.`stg_support_tickets`
),
orders AS (
    SELECT
        *
    FROM `ecommerce-ai-analytics`.`ecommerce_ai_int`.`int_order_revenue`
)

SELECT
    t.ticket_id,
    t.user_id,
    t.order_id,
    t.created_at AS ticket_created_at,
    
    te.issue_type,
    te.priority,
    te.refund_risk,
    te.root_cause,
    te.sentiment,
    te.confidence_score,

    o.order_created_at,
    o.order_status,
    o.total_order_revenue,
    o.total_profit_margin,
    o.is_returned_order,
    o.is_cancelled_order,
    te.requires_human_review,
   
FROM tickets t
LEFT JOIN tickets_extractions te ON t.ticket_id = te.ticket_id
LEFT JOIN orders o ON t.order_id = o.order_id