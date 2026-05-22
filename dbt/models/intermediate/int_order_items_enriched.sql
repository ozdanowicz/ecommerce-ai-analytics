{{ config(
    schema='ecommerce_ai_int',
    materialized='view'
) }}
WITH orders AS (
    SELECT *
    FROM {{ ref('stg_orders') }}
),

order_items AS (
    SELECT *
    FROM {{ ref('stg_order_items') }}
),

products AS (
    SELECT *
    FROM {{ ref('stg_products') }}
),

users AS (
    SELECT *
    FROM {{ ref('stg_users') }}
)

SELECT 
    oi.order_item_id,
    oi.order_id,
    oi.product_id,
    oi.user_id,

    p.product_name,
    p.product_brand,
    p.product_category,
    p.department,

    o.order_status,
    o.created_at AS order_created_at,
    o.returned_at AS order_returned_at,
    o.shipped_at AS order_shipped_at,
    o.delivered_at AS order_delivered_at,

    oi.sale_price,
    p.product_cost,
    (oi.sale_price - p.product_cost) AS item_margin,
    SAFE_DIVIDE((oi.sale_price - p.product_cost), p.product_cost) AS item_margin_pct,

    CASE 
        WHEN o.returned_at IS NOT NULL OR o.order_status = 'returned' THEN TRUE
        ELSE FALSE
    END AS is_returned,

    CASE 
        WHEN o.delivered_at IS NOT NULL and o.order_status = 'complete' THEN TRUE
        ELSE FALSE
    END AS is_delivered,

    CASE 
        WHEN o.order_status = 'cancelled' THEN TRUE
        ELSE FALSE
    END AS is_cancelled,

    CASE 
        WHEN o.order_status = 'processing' THEN TRUE
        ELSE FALSE
    END AS is_processing,

    CASE 
        WHEN o.order_status = 'shipped' THEN TRUE
        ELSE FALSE
    END AS is_shipped,
    u.country AS user_country,
    u.traffic_source AS traffic_source


FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
LEFT JOIN users u ON oi.user_id = u.user_id