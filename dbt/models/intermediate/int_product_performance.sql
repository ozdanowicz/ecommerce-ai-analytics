{{ config(
    schema='ecommerce_ai_int',
    materialized='view'
) }}

WITH order_item AS(
    SELECT *
    FROM {{ ref('int_order_items_enriched') }}
)
SELECT
    product_id,
    ANY_VALUE(product_name) AS product_name,
    ANY_VALUE(product_brand) AS product_brand,
    ANY_VALUE(product_category) AS product_category,
    ANY_VALUE(department) AS department,
    SUM(profit_margin) AS total_profit_margin, 
    SUM(sale_price) AS total_revenue,
    SUM(CASE WHEN is_returned THEN 1 ELSE 0 END) AS returned_items,
    COUNT(order_item_id) AS items_sold,
    SAFE_DIVIDE(SUM(CASE WHEN is_returned THEN 1 ELSE 0 END), COUNT(order_item_id)) AS return_rate,
    AVG(sale_price) AS avg_sale_price
FROM order_item
GROUP BY product_id