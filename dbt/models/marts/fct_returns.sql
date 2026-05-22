{{ config(
    schema='ecommerce_ai_marts',
    materialized='table'
) }}

SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    item_cost,
    item_revenue,
    item_margin,
    item_margin_pct, 
    order_returned_at,
    is_returned
FROM {{ ref('int_order_items_enriched') }} 
WHERE is_returned = TRUE