{{ config(
    schema='ecommerce_ai_marts',
    materialized='table'
) }}

SELECT
    order_id,
    user_id,
    order_status,
    order_created_at,

    total_order_cost, 
    total_order_revenue,
    total_order_margin,

    order_items_count,
    returned_items_count,
    
    is_returned_order,
    is_cancelled_order
FROM {{ ref('int_order_revenue') }}

