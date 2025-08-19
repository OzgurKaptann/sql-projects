-- Görev 3 SQL (Temizlenmiş)
WITH base AS (
  SELECT
    DATE(TIMESTAMP_MICROS(event_timestamp)) AS event_date,
    COALESCE(NULLIF(user_id, ''), user_pseudo_id) AS user_key,
    SAFE_CAST((
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id'
    ) AS STRING) AS session_id,
    event_name,
    COALESCE(
      traffic_source.source,
      (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key IN ('source', 'utm_source') LIMIT 1)
    ) AS source,
    COALESCE(
      traffic_source.medium,
      (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key IN ('medium', 'utm_medium') LIMIT 1)
    ) AS medium,
    COALESCE(
      traffic_source.name,
      (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key IN ('campaign', 'utm_campaign') LIMIT 1)
    ) AS campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20210101' AND '20211231'
    AND event_name IN (
      'session_start','view_item','add_to_cart','begin_checkout',
      'add_shipping_info','add_payment_info','purchase'
    )
),
sessions AS (
  SELECT
    event_date,
    source, medium, campaign,
    CONCAT(user_key, '-', session_id) AS full_session_id,
    MAX(event_name = 'add_to_cart')       AS step_add_to_cart,
    MAX(event_name = 'begin_checkout')    AS step_begin_checkout,
    MAX(event_name = 'purchase')          AS step_purchase
  FROM base
  WHERE event_name IN ('session_start', 'add_to_cart', 'begin_checkout', 'purchase')
  GROUP BY event_date, source, medium, campaign, user_key, session_id
)
SELECT
  event_date, source, medium, campaign,
  COUNT(DISTINCT full_session_id) AS user_sessions_count,
  SUM(CAST(step_add_to_cart AS INT64))       AS visit_to_cart,
  SUM(CAST(step_begin_checkout AS INT64))    AS visit_to_checkout,
  SUM(CAST(step_purchase AS INT64))          AS visit_to_purchase
FROM sessions
GROUP BY event_date, source, medium, campaign
ORDER BY event_date, source, medium, campaign;
