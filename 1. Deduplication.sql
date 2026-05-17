Використовуємо віконну функцію ROW_NUMBER() — вона нумерує рядки всередині групи.
Групуємо по оголошенню і дню, сортуємо від найновішого. -
WITH deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ad_id, date
            ORDER BY timestamp DESC
        ) AS rn
    FROM `marketing-analytics-skelar.marketing_raw.marketing_ads_raw`
)
SELECT *
FROM deduped
WHERE rn = 1
