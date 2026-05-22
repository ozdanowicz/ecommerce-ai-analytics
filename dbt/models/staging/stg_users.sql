{{ config(
    schema='ecommerce_ai_stg',
    materialized='view'
) }}
SELECT
    CAST(id AS INT64) AS user_id,
    NULLIF(TRIM(first_name), '') AS first_name,
    NULLIF(TRIM(last_name), '') AS last_name,
    NULLIF(TRIM(email), '') AS email,
    CAST(age AS INT64) AS age,
    NULLIF(LOWER(TRIM(gender)), '') AS gender,
    NULLIF(TRIM(state), '') AS state,
    NULLIF(TRIM(street_address), '') AS street_address,
    NULLIF(TRIM(postal_code), '') AS postal_code,
    NULLIF(TRIM(city), '') AS city,
    NULLIF(TRIM(country), '') AS country,
    CAST(latitude AS NUMERIC) AS latitude,
    CAST(longitude AS NUMERIC) AS longitude,
    NULLIF(TRIM(traffic_source), '') AS traffic_source,
    CAST(created_at AS TIMESTAMP) AS created_at
FROM {{source('raw_data', 'raw_users')}}