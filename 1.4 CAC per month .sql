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
    SELECT
        source,
        ad_id,
        date,
        spend,
        registrations
    FROM deduped
    WHERE rn = 1
),

daily_delta AS (
    SELECT
        source,
        ad_id,
        date,
        spend - LAG(spend) OVER (
            PARTITION BY ad_id
            ORDER BY date
        ) AS daily_spend,

        registrations - LAG(registrations) OVER (
            PARTITION BY ad_id
            ORDER BY date
        ) AS daily_registrations

    FROM daily_last
),

monthly AS (
    SELECT
        source,
        DATE_TRUNC(date, MONTH) AS month,
        SUM(daily_spend)         AS monthly_spend,
        SUM(daily_registrations) AS monthly_registrations
    FROM daily_delta
    WHERE daily_spend IS NOT NULL
    GROUP BY source, month
)

SELECT
    month,
    source,
    ROUND(monthly_spend, 2)                                    AS total_spend,
    monthly_registrations                                      AS total_registrations,
    ROUND(monthly_spend / monthly_registrations, 2)           AS cac
FROM monthly
ORDER BY month, source
