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
    -- останній snapshot за кожен день
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
    -- рахуємо денну дельту через LAG
    SELECT
        source,
        ad_id,
        date,
        spend - LAG(spend) OVER (
            PARTITION BY ad_id
            ORDER BY date
        ) AS daily_spend,

        impressions - LAG(impressions) OVER (
            PARTITION BY ad_id
            ORDER BY date
        ) AS daily_impressions,

        clicks - LAG(clicks) OVER (
            PARTITION BY ad_id
            ORDER BY date
        ) AS daily_clicks,

        installs - LAG(installs) OVER (
            PARTITION BY ad_id
            ORDER BY date
        ) AS daily_installs,

        registrations - LAG(registrations) OVER (
            PARTITION BY ad_id
            ORDER BY date
        ) AS daily_registrations

    FROM daily_last
),

daily AS (
    -- агрегуємо по (source, date), ігноруємо NULL (перший день кампанії)
    SELECT
        source,
        date,
        SUM(daily_spend)         AS daily_spend,
        SUM(daily_impressions)   AS daily_impressions,
        SUM(daily_clicks)        AS daily_clicks,
        SUM(daily_installs)      AS daily_installs,
        SUM(daily_registrations) AS daily_registrations
    FROM daily_delta
    WHERE daily_spend IS NOT NULL
    GROUP BY source, date
),

channel_metrics AS (
    SELECT
        source,
        ROUND(SUM(daily_spend), 2)                                                        AS total_spend,
        ROUND(SUM(daily_spend) / SUM(daily_impressions) * 1000, 2)                       AS cpm,
        ROUND(CAST(SUM(daily_clicks) AS FLOAT64) / SUM(daily_impressions) * 100, 2)      AS ctr_pct,
        ROUND(CAST(SUM(daily_installs) AS FLOAT64) / SUM(daily_clicks) * 100, 2)         AS cr_click_install_pct,
        ROUND(CAST(SUM(daily_registrations) AS FLOAT64) / SUM(daily_installs) * 100, 2)  AS cr_install_reg_pct,
        ROUND(SUM(daily_spend) / SUM(daily_registrations), 2)                            AS cac
    FROM daily
    GROUP BY source
)

SELECT
    source,
    total_spend,
    cpm,
    ctr_pct,
    cr_click_install_pct,
    cr_install_reg_pct,
    cac,
    CASE source
        WHEN 'tiktok' THEN 8.50
        WHEN 'meta'   THEN 6.20
        WHEN 'google' THEN 12.40
    END AS ltv,
    ROUND(
        CASE source
            WHEN 'tiktok' THEN 8.50
            WHEN 'meta'   THEN 6.20
            WHEN 'google' THEN 12.40
        END / cac, 2
    ) AS ltv_cac_ratio
FROM channel_metrics
ORDER BY cac
