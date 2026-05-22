

  create or replace view `ecommerce-ai-analytics`.`ecommerce_ai_stg`.`stg_products`
  OPTIONS()
  as 

SELECT
    CAST(id AS INT64) AS product_id,
    CAST(cost AS NUMERIC) AS product_cost,
    CAST(retail_price AS NUMERIC) AS retail_price,
    NULLIF(LOWER(TRIM(category)), '') AS product_category,
    NULLIF(TRIM(name), '') AS product_name,
    NULLIF(LOWER(TRIM(brand)), '') AS product_brand,
    NULLIF(LOWER(TRIM(department)), '') AS department,
    NULLIF(TRIM(sku), '') AS sku,
    CAST(distribution_center_id AS INT64) AS distribution_center_id
FROM `ecommerce-ai-analytics`.`ecommerce_ai_raw`.`raw_products`;

