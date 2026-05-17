-- Використовуємо віконну функцію ROW_NUMBER() — вона нумерує рядки всередині групи. 
--групуємо по оголошенню і дню
-- сортуємо від найновішого
SELECT
  source,
  COUNT(*) AS total_rows,
  MIN(date) AS first_date,
  MAX(date) AS last_date,
  COUNT(DISTINCT ad_id) AS unique_ads
FROM `marketing-analytics-skelar.marketing_raw.marketing_ads_raw`
GROUP BY source
ORDER BY source;
