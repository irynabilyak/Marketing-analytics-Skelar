WITH deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ad_id, date
            ORDER BY timestamp DESC
        ) AS rn
    FROM `marketing-analytics-skelar.marketing_raw.marketing_ads_raw`
),

daily_last AS (
    -- останній snapshot за кожен день по кожному оголошенню
    SELECT
        source,
        ad_id,
        date,
        spend,
        impressions,
        clicks,
        installs,
        registrations
    FROM deduped
    WHERE rn = 1
),

daily_delta AS (
    -- рахуємо скільки витратили/отримали саме за цей день
    SELECT
        source,
        ad_id,
        date,
        spend - LAG(spend) OVER (PARTITION BY ad_id ORDER BY date)               AS daily_spend,
        impressions - LAG(impressions) OVER (PARTITION BY ad_id ORDER BY date)   AS daily_impressions,
        clicks - LAG(clicks) OVER (PARTITION BY ad_id ORDER BY date)             AS daily_clicks,
        installs - LAG(installs) OVER (PARTITION BY ad_id ORDER BY date)         AS daily_installs,
        registrations - LAG(registrations) OVER (PARTITION BY ad_id ORDER BY date) AS daily_registrations
    FROM daily_last
)

-- Крок 2: агрегуємо по (source, date)
SELECT
    source,
    date,
    SUM(daily_spend)         AS daily_spend,
    SUM(daily_impressions)   AS daily_impressions,
    SUM(daily_clicks)        AS daily_clicks,
    SUM(daily_installs)      AS daily_installs,
    SUM(daily_registrations) AS daily_registrations
FROM daily_delta
WHERE daily_spend IS NOT NULL  -- перший день кампанії не має попереднього значення
GROUP BY source, date
ORDER BY source, date
