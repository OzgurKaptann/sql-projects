-- Görev 5 SQL (Temizlenmiş)
WITH base AS (
  SELECT
    COALESCE(NULLIF(user_id, ''), user_pseudo_id) AS user_key,
    SAFE_CAST((
      SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id'
    ) AS STRING) AS session_id,
    event_name,
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'engagement_time_msec') AS engagement_time_msec
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20210101' AND '20211231'
    AND event_name IN ('session_start','user_engagement','session_engaged','purchase')
),
session_level AS (
  SELECT
    user_key, session_id,
    MAX(event_name = 'session_start')    AS has_session,
    MAX(event_name = 'session_engaged')  AS session_engaged_flag,
    SUM(COALESCE(engagement_time_msec, 0)) AS engagement_time_msec_sum,
    MAX(event_name = 'purchase')         AS purchase_flag
  FROM base
  WHERE user_key IS NOT NULL AND session_id IS NOT NULL
  GROUP BY user_key, session_id
),
sessions AS (
  SELECT
    CONCAT(user_key, '-', session_id)                     AS full_session_id,
    CAST(session_engaged_flag AS INT64)                  AS session_engaged_int,
    COALESCE(engagement_time_msec_sum, 0)                AS engagement_time_msec_sum,
    CAST(purchase_flag AS INT64)                         AS purchase_int
  FROM session_level
  WHERE has_session = TRUE
)
SELECT
  CORR(CAST(session_engaged_int AS FLOAT64), CAST(purchase_int AS FLOAT64)) AS corr_engaged_vs_purchase,
  CORR(CAST(engagement_time_msec_sum AS FLOAT64), CAST(purchase_int AS FLOAT64)) AS corr_time_vs_purchase,
  COUNT(*) AS session_count
FROM sessions;
