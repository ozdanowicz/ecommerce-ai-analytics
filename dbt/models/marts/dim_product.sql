{{ config(
    schema='ecommerce_ai_marts',
    materialized='table'
) }}

SELECT
    product_id,
    product_name,
    product_brand,
    product_category,
    department,
    product_cost,
    retail_price,
    sku,
    distribution_center_id
FROM {{ ref('stg_products') }}