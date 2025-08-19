-- Görev 2 SQL (Temizlenmiş)
SELECT
  TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,
  COALESCE(NULLIF(user_id, ''), user_pseudo_id) AS user_key,
  CONCAT(
    COALESCE(NULLIF(user_id, ''), user_pseudo_id), '-',
    SAFE_CAST((
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id'
    ) AS STRING)
  ) AS session_id,
  event_name,
  geo.country AS country,
  device.category AS device_category,
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
  );
