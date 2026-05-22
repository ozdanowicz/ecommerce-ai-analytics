{{ config(
    schema='ecommerce_ai_stg',
    materialized='view'
) }}

SELECT
    CAST(order_id AS INT64) AS order_id,
    CAST(user_id AS INT64) AS user_id,

    NULLIF(LOWER(TRIM(status)), '') AS order_status,
    NULLIF(LOWER(TRIM(gender)), '') AS gender,

    CAST(created_at AS TIMESTAMP) AS created_at,
    CAST(returned_at AS TIMESTAMP) AS returned_at,
    CAST(shipped_at AS TIMESTAMP) AS shipped_at,
    CAST(delivered_at AS TIMESTAMP) AS delivered_at,
    CAST(num_of_item AS INT64) AS order_items_count

FROM {{ source('raw_data', 'raw_orders') }}