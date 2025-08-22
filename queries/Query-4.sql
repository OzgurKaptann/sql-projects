WITH google_monthly AS (                          -- Google
  SELECT
    DATE_TRUNC('month', gad.ad_date)::date      AS month_start,
    gad.campaign_name::text                     AS campaign_key,
    SUM(COALESCE(gad.reach, 0))::numeric        AS monthly_reach
  FROM public.google_ads_basic_daily AS gad
  GROUP BY 1, 2),
  
facebook_monthly AS (                            -- Facebook
  SELECT
    DATE_TRUNC('month', fad.ad_date)::date      AS month_start,
    COALESCE(fc.campaign_name, fad.campaign_id::text) AS campaign_key,
    SUM(COALESCE(fad.reach, 0))::numeric        AS monthly_reach
  FROM public.facebook_ads_basic_daily AS fad
  LEFT JOIN public.facebook_campaign AS fc
    ON fc.campaign_id = fad.campaign_id
  GROUP BY 1, 2),
  
monthly_union AS (                               -- İki platformu tek akışta birleştir
  SELECT * FROM google_monthly
  UNION ALL
  SELECT * FROM facebook_monthly),
  
monthly_rollup AS (                               --platformlar arası ay toplamı
  SELECT
    month_start,
    campaign_key,
    SUM(monthly_reach) AS monthly_reach
  FROM monthly_union
  GROUP BY 1, 2),
  
monthly_with_diff AS (                            -- Bir önceki aya göre artış (MoM)
  SELECT
    campaign_key,
    month_start,
    monthly_reach,
    monthly_reach
      - LAG(monthly_reach) OVER (PARTITION BY campaign_key ORDER BY month_start)
      AS reach_increase
  FROM monthly_rollup)
  
SELECT
  campaign_key,
  month_start                                 AS month,
  ROUND(monthly_reach, 2)                     AS monthly_reach,
  ROUND(reach_increase, 2)                    AS reach_increase
FROM monthly_with_diff
WHERE reach_increase IS NOT NULL               -- ilk ayı dışarıda bırak
ORDER BY reach_increase DESC
LIMIT 1;

