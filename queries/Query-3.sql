WITH g AS (
  SELECT
    DATE_TRUNC('week', ad_date)::date                  AS week_start,
    COALESCE(campaign_name, '(unknown)')              AS campaign_key,
    SUM(COALESCE(value, 0))::numeric                  AS total_value
  FROM public.google_ads_basic_daily
  GROUP BY 1, 2
),

f AS (
  SELECT
    DATE_TRUNC('week', fad.ad_date)::date                                                 AS week_start,
    COALESCE(fc.campaign_name, fad.campaign_id, '(unknown)')                              AS campaign_key,
    SUM(COALESCE(fad.value, 0))::numeric                                                  AS total_value
  FROM public.facebook_ads_basic_daily fad
  LEFT JOIN public.facebook_campaign fc
    ON fc.campaign_id = fad.campaign_id
  GROUP BY 1, 2
),

u AS (
  SELECT * FROM g
  UNION ALL
  SELECT * FROM f
),

tot AS (
  SELECT
    week_start,
    campaign_key,
    SUM(total_value) AS total_value
  FROM u
  GROUP BY 1, 2
)

SELECT
  week_start,
  campaign_key,
  ROUND(total_value, 2) AS total_value
FROM tot
ORDER BY total_value DESC
LIMIT 1;
