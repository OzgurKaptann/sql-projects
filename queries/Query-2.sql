WITH per_platform_day AS (
  SELECT
    ad_date::date AS d,
    SUM(value)::numeric AS revenue,
    SUM(spend)::numeric AS cost
  FROM public.google_ads_basic_daily
  GROUP BY ad_date

  UNION ALL

  SELECT
    ad_date::date AS d,
    SUM(value)::numeric AS revenue,
    SUM(spend)::numeric AS cost
  FROM public.facebook_ads_basic_daily
  GROUP BY ad_date
),

daily_totals AS (
  SELECT
    d,
    SUM(revenue) AS total_revenue,
    SUM(cost)    AS total_cost
  FROM per_platform_day
  GROUP BY d)
  
SELECT
  d AS date,
  ROUND( (total_revenue - total_cost) / NULLIF(total_cost, 0), 2 ) AS romi
FROM daily_totals
ORDER BY romi DESC NULLS LAST, date ASC
LIMIT 5;
