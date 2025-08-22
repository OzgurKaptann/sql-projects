WITH google_daily AS (
  SELECT
    ad_date::date AS ad_date,
    SUM(spend::numeric) AS day_spend
  FROM public.google_ads_basic_daily
  GROUP BY ad_date),
  
facebook_daily AS (
  SELECT
    ad_date::date AS ad_date,
    SUM(spend::numeric) AS day_spend
  FROM public.facebook_ads_basic_daily
  GROUP BY ad_date),
  
unioned AS (
  SELECT ad_date, 'Google' AS platform, day_spend FROM google_daily
  UNION ALL
  SELECT ad_date, 'Facebook' AS platform, day_spend FROM facebook_daily)
  
SELECT
  ad_date,
  platform,
  ROUND(AVG(day_spend), 2) AS avg_spend,
  ROUND(MAX(day_spend), 2) AS max_spend,
  ROUND(MIN(day_spend), 2) AS min_spend
FROM unioned
GROUP BY ad_date, platform
ORDER BY ad_date, platform;
