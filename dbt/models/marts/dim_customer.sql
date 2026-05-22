{{ config(
    schema='ecommerce_ai_marts',
    materialized='table'
) }}

SELECT
    user_id,
    first_name,
    last_name,
    email,
    age, 
    gender,
    state, 
    city, 
    country,
    traffic_source,
    created_at
FROM {{ ref('stg_users') }}