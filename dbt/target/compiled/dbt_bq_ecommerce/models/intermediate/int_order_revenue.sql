

WITH order_items AS (
    SELECT
        *
    FROM `ecommerce-ai-analytics`.`ecommerce_ai_int`.`int_order_items_enriched`
)

SELECT
    order_id,
    user_id,

    MIN(order_created_at) AS order_created_at,
    ANY_VALUE(order_status) AS order_status,

    SUM(product_cost) AS total_order_cost,
    SUM(sale_price) AS total_order_revenue,
    SUM(profit_margin) AS total_profit_margin,
    COUNT(order_item_id) AS order_items_count,
    SUM(CASE WHEN is_returned THEN 1 ELSE 0 END) AS returned_items_count,
    MAX(CASE WHEN is_returned THEN TRUE ELSE FALSE END) AS is_returned_order,
    MAX(CASE WHEN is_cancelled THEN TRUE ELSE FALSE END) AS is_cancelled_order,
    ANY_VALUE(user_country) AS user_country,
    ANY_VALUE(traffic_source) AS traffic_source

FROM order_items
GROUP BY order_id, user_id