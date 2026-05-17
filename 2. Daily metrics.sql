daily AS (
    SELECT
        source,
        date,
        SUM(spend)         AS daily_spend,
        SUM(impressions)   AS daily_impressions,
        SUM(clicks)        AS daily_clicks,
        SUM(installs)      AS daily_installs,
        SUM(registrations) AS daily_registrations
    FROM deduped
    WHERE rn = 1
    GROUP BY source, date
)
