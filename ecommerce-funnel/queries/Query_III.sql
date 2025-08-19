-- Görev 4 SQL (Temizlenmiş)
WITH base AS (
  SELECT
    TIMESTAMP_MICROS(event_timestamp) AS event_ts,
    COALESCE(NULLIF(user_id, ''), user_pseudo_id) AS user_key,
    SAFE_CAST((
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id'
    ) AS STRING) AS session_id,
    event_name,
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'page_location') AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20200101' AND '20201231'
),
session_page_candidates AS (
  SELECT
    user_key, session_id, event_name, page_location, event_ts,
    ROW_NUMBER() OVER (
      PARTITION BY user_key, session_id
      ORDER BY
        CASE WHEN event_name = 'session_start' AND page_location IS NOT NULL THEN 0 ELSE 1 END,
        event_ts
    ) AS rn
  FROM base
  WHERE page_location IS NOT NULL
    AND event_name IN ('session_start', 'page_view')
),
landing_pages AS (
  SELECT
    user_key, session_id,
    REGEXP_EXTRACT(page_location, r'https?://[^/]+([^?#]*)') AS page_path
  FROM session_page_candidates
  WHERE rn = 1
),
purchase_sessions AS (
  SELECT DISTINCT
    COALESCE(NULLIF(user_id, ''), user_pseudo_id) AS user_key,
    SAFE_CAST((
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id'
    ) AS STRING) AS session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20200101' AND '20201231'
    AND event_name = 'purchase'
),
sessions_final AS (
  SELECT
    lp.user_key, lp.session_id,
    COALESCE(lp.page_path, '(unknown)') AS page_path,
    IF(ps.user_key IS NOT NULL, TRUE, FALSE) AS has_purchase
  FROM landing_pages lp
  LEFT JOIN purchase_sessions ps
    ON lp.user_key = ps.user_key AND lp.session_id = ps.session_id
)
SELECT
  page_path,
  COUNT(DISTINCT CONCAT(user_key, '-', session_id)) AS unique_sessions,
  COUNTIF(has_purchase)                             AS purchases,
  SAFE_DIVIDE(COUNTIF(has_purchase),
              COUNT(DISTINCT CONCAT(user_key, '-', session_id))) AS purchase_conversion_rate
FROM sessions_final
GROUP BY page_path
ORDER BY purchase_conversion_rate DESC NULLS LAST, unique_sessions DESC;
