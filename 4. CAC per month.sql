WITH deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ad_id, date
            ORDER BY timestamp DESC
        ) AS rn
    FROM `marketing-analytics-skelar.marketing_raw.marketing_ads_raw`
),

daily AS (
    SELECT
        source,
        DATE_TRUNC(date, MONTH) AS month,
        SUM(spend)              AS daily_spend,
        SUM(registrations)      AS daily_registrations
    FROM deduped
    WHERE rn = 1
    GROUP BY source, month
)

SELECT
    month,
    source,
    ROUND(SUM(daily_spend), 2)                               AS total_spend,
    ROUND(SUM(daily_spend) / SUM(daily_registrations), 2)   AS cac
FROM daily
GROUP BY month, source
ORDER BY month, source
