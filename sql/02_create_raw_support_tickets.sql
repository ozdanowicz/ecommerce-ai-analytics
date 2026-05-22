-- 02_create_raw_support_tickets.sql
-- Generate synthetic raw support tickets using valid order_id and user_id
-- from your existing BigQuery raw e-commerce tables.

CREATE OR REPLACE TABLE `{{ project_id }}.{{ raw_dataset }}.raw_support_tickets` AS

WITH order_product_sample AS (
  SELECT
    o.order_id,
    o.user_id,
    o.status AS order_status,
    o.created_at AS order_created_at,
    o.shipped_at,
    o.delivered_at,
    o.returned_at,

    oi.id AS order_item_id,
    oi.product_id,
    oi.sale_price,

    p.category AS product_category,
    p.department AS product_department,
    p.brand AS product_brand,
    p.name AS product_name,

    ROW_NUMBER() OVER (
      PARTITION BY o.order_id
      ORDER BY oi.sale_price DESC, oi.id
    ) AS item_rank

  FROM `{{ project_id }}.{{ raw_dataset }}.raw_orders` AS o

  JOIN `{{ project_id }}.{{ raw_dataset }}.raw_order_items` AS oi
    ON o.order_id = oi.order_id
   AND o.user_id = oi.user_id

  LEFT JOIN `{{ project_id }}.{{ raw_dataset }}.raw_products` AS p
    ON oi.product_id = p.id

  WHERE o.order_id IS NOT NULL
    AND o.user_id IS NOT NULL
    AND o.created_at IS NOT NULL
)

one_item_per_order AS (
  SELECT
    *
  FROM order_product_sample
  WHERE item_rank = 1
),

ticket_candidates AS (
  SELECT
    *,
    MOD(ABS(FARM_FINGERPRINT(CAST(order_id AS STRING))), 10) AS issue_idx,
    MOD(ABS(FARM_FINGERPRINT(CONCAT(CAST(order_id AS STRING), '-channel'))), 4) AS channel_idx,
    MOD(ABS(FARM_FINGERPRINT(CONCAT(CAST(order_id AS STRING), '-days'))), 14) AS days_after_order

  FROM one_item_per_order

  -- Creates tickets for around 10% of orders.
  -- Change < 10 to:
  -- < 5  for around 5%
  -- < 20 for around 20%
  WHERE MOD(
    ABS(FARM_FINGERPRINT(CONCAT(CAST(order_id AS STRING), '-ticket-sample'))),
    100
  ) < 10
),

limited_candidates AS (
  SELECT
    *
  FROM ticket_candidates
  ORDER BY order_created_at DESC
  LIMIT 2000
),

ticket_base AS (
  SELECT
    FORMAT(
      'TCK-%06d',
      ROW_NUMBER() OVER (ORDER BY order_created_at, order_id)
    ) AS ticket_id,

    order_id,
    user_id,

    TIMESTAMP_ADD(
      COALESCE(delivered_at, shipped_at, order_created_at),
      INTERVAL CAST(1 + days_after_order AS INT64) DAY
    ) AS created_at,

    CASE channel_idx
      WHEN 0 THEN 'email'
      WHEN 1 THEN 'chat'
      WHEN 2 THEN 'web_form'
      ELSE 'phone'
    END AS ticket_channel,

    CASE issue_idx
      WHEN 0 THEN 'delivery_delay'
      WHEN 1 THEN 'damaged_package'
      WHEN 2 THEN 'wrong_size'
      WHEN 3 THEN 'poor_quality'
      WHEN 4 THEN 'missing_item'
      WHEN 5 THEN 'refund_request'
      WHEN 6 THEN 'payment_issue'
      WHEN 7 THEN 'tracking_issue'
      WHEN 8 THEN 'customer_service'
      ELSE 'other'
    END AS synthetic_issue_category,

    product_category,
    product_department,
    product_brand,
    product_name,
    order_status,
    sale_price

  FROM limited_candidates
)

SELECT
  ticket_id,
  order_id,
  user_id,
  created_at,
  ticket_channel,

  CASE synthetic_issue_category

    WHEN 'delivery_delay' THEN CONCAT(
      'My order ', CAST(order_id AS STRING),
      ' was delivered later than expected. I needed the item urgently and the delivery updates were not helpful.'
    )

    WHEN 'damaged_package' THEN CONCAT(
      'The package for order ', CAST(order_id AS STRING),
      ' arrived damaged. The ', COALESCE(product_category, 'product'),
      ' item may also be affected and I would like this checked.'
    )

    WHEN 'wrong_size' THEN CONCAT(
      'I ordered a ', COALESCE(product_category, 'product'),
      ' item but the size does not fit as expected. I need help with an exchange or return.'
    )

    WHEN 'poor_quality' THEN CONCAT(
      'The quality of the ', COALESCE(product_category, 'product'),
      ' item is worse than expected. It does not look like the description and I am disappointed.'
    )

    WHEN 'missing_item' THEN CONCAT(
      'My order ', CAST(order_id AS STRING),
      ' seems incomplete. One item is missing from the package and I need support to resolve this.'
    )

    WHEN 'refund_request' THEN CONCAT(
      'I want a refund for order ', CAST(order_id AS STRING),
      '. The product did not meet expectations and I do not want a replacement.'
    )

    WHEN 'payment_issue' THEN CONCAT(
      'I had a payment issue with order ', CAST(order_id AS STRING),
      '. I am not sure if I was charged correctly and need confirmation.'
    )

    WHEN 'tracking_issue' THEN CONCAT(
      'I cannot track order ', CAST(order_id AS STRING),
      '. The tracking link does not work and I do not know where the package is.'
    )

    WHEN 'customer_service' THEN CONCAT(
      'I contacted customer service about order ', CAST(order_id AS STRING),
      ' but I have not received a useful response. Please escalate this case.'
    )

    ELSE CONCAT(
      'I need help with order ', CAST(order_id AS STRING),
      '. The issue is not listed in the standard options and I would like someone to review it.'
    )

  END AS ticket_text

FROM ticket_base;