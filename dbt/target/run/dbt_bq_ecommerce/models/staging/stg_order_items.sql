

  create or replace view `ecommerce-ai-analytics`.`ecommerce_ai_stg`.`stg_order_items`
  OPTIONS()
  as 

SELECT
    CAST(id AS INT64) AS order_item_id,
    CAST(product_id AS INT64) AS product_id,
    CAST(order_id AS INT64) AS order_id,
    CAST(user_id AS INT64) AS user_id,
    CAST(inventory_item_id AS INT64) AS inventory_item_id,
    NULLIF(LOWER(TRIM(status)), '') AS order_status,
    CAST(sale_price AS NUMERIC) AS sale_price,
    CAST(created_at AS TIMESTAMP) AS created_at,
    CAST(returned_at AS TIMESTAMP) AS returned_at,
    CAST(shipped_at AS TIMESTAMP) AS shipped_at,
    CAST(delivered_at AS TIMESTAMP) AS delivered_at
FROM `ecommerce-ai-analytics`.`ecommerce_ai_raw`.`raw_order_items`;

