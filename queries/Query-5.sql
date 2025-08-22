WITH google_daily_impressions AS (              -- Google
  SELECT
    gad.ad_date::date                          AS activity_date,
    'Google'::text                             AS platform_name,
    gad.adset_name::text                       AS adset_display_name,
    SUM(COALESCE(gad.impressions, 0))          AS impressions_count
  FROM public.google_ads_basic_daily AS gad
  GROUP BY 1, 2, 3),
  
facebook_daily_impressions_base AS (            -- Facebook
  SELECT
    fad.ad_date::date                          AS activity_date,
    fad.adset_id                               AS adset_id,
    SUM(COALESCE(fad.impressions, 0))          AS impressions_count
  FROM public.facebook_ads_basic_daily AS fad
  GROUP BY 1, 2),
  
facebook_daily_impressions AS (                 
  SELECT
    fdb.activity_date                           AS activity_date,
    'Facebook'::text                            AS platform_name,
    COALESCE(fa.adset_name, fdb.adset_id)::text AS adset_display_name,
    fdb.impressions_count                       AS impressions_count
  FROM facebook_daily_impressions_base AS fdb
  LEFT JOIN public.facebook_adset AS fa
    ON fa.adset_id = fdb.adset_id),
    
all_daily_impressions AS (                      -- İki platformu birleştir
  SELECT * FROM google_daily_impressions
  UNION ALL
  SELECT * FROM facebook_daily_impressions),
  
daily_totals AS (                               -- Gün+adset bazında toplam
  SELECT
    platform_name,
    adset_display_name,
    activity_date,
    SUM(impressions_count) AS impressions_count
  FROM all_daily_impressions
  GROUP BY 1, 2, 3),
  
active_days AS (                                -- Yalnızca gösterim olan günler
  SELECT
    platform_name,
    adset_display_name,
    activity_date
  FROM daily_totals
  WHERE impressions_count > 0),
  
consecutive_groups AS (                         -- Gaps & Islands: ardışık gün grubu anahtarı
  SELECT
    platform_name,
    adset_display_name,
    activity_date,
    activity_date
      - (ROW_NUMBER() OVER (
            PARTITION BY platform_name, adset_display_name
            ORDER BY activity_date
        ))::int * INTERVAL '1 day' AS consecutive_group_key
  FROM active_days),
  
consecutive_spans AS (                          -- Her grubun başlangıç/bitiş/gün sayısı
  SELECT
    platform_name,
    adset_display_name,
    MIN(activity_date)                          AS date_start,
    MAX(activity_date)                          AS date_end,
    COUNT(*)                                    AS consecutive_days
  FROM consecutive_groups
  GROUP BY platform_name, adset_display_name, consecutive_group_key)
  
SELECT
  platform_name,
  adset_display_name,
  date_start,
  date_end,
  consecutive_days
FROM consecutive_spans
ORDER BY consecutive_days DESC, date_start
LIMIT 1;

