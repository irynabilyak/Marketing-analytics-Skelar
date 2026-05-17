WITH deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ad_id, date
            ORDER BY timestamp DESC
        ) AS rn
    FROM `marketing-analytics-skelar.marketing_raw.marketing_ads_raw`
),

latest_snapshots AS (
    SELECT *
    FROM deduplicated
    WHERE rn = 1
)

SELECT
    source,
    date,

    SUM(spend) AS daily_spend,
    SUM(impressions) AS daily_impressions,
    SUM(clicks) AS daily_clicks,
    SUM(installs) AS daily_installs,
    SUM(registrations) AS daily_registrations

FROM latest_snapshots
GROUP BY source, date
ORDER BY date, source;
