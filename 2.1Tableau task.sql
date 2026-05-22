WITH users_agg AS (
  SELECT
    registration_date        AS date,
    channel,
    geo,
    device_os,
    COUNT(id_user)           AS new_users,
    SUM(is_payer)            AS payers,
    SUM(revenue_7d)          AS revenue_7d,
    SUM(revenue_90d)         AS revenue_90d
  FROM `marketing-analytics-skelar.marketing.users`
  WHERE registration_date >= '2025-01-01'
  GROUP BY 1, 2, 3, 4
),

spend_agg AS (
  SELECT
    date,
    channel,
    geo,
    SUM(spend) AS spend
  FROM `marketing-analytics-skelar.marketing.spend`
  WHERE date >= '2025-01-01'
  GROUP BY 1, 2, 3
),

users_total AS (
  SELECT
    date,
    channel,
    geo,
    SUM(new_users) AS total_users
  FROM users_agg
  GROUP BY 1, 2, 3
)

SELECT
  s.date,
  s.channel,
  s.geo,
  u.device_os,
  ROUND(s.spend * SAFE_DIVIDE(u.new_users, t.total_users), 2)  AS spend,
  u.new_users,
  u.payers,
  u.revenue_7d,
  u.revenue_90d,
  SAFE_DIVIDE(u.payers, u.new_users)                            AS cvr,
  SAFE_DIVIDE(u.revenue_7d, s.spend)                           AS roas_7d,
  SAFE_DIVIDE(u.revenue_90d, s.spend)                          AS roas_90d,
  SAFE_DIVIDE(u.revenue_90d, u.new_users)                      AS arpu_90d,
  ROUND(SAFE_DIVIDE(s.spend * SAFE_DIVIDE(u.new_users, t.total_users), u.new_users), 2)  AS cac,
  ROUND(SAFE_DIVIDE(s.spend * SAFE_DIVIDE(u.new_users, t.total_users), u.payers), 2)     AS cppu,
  FORMAT_DATE('%Y-%m', s.date)                                 AS month,
  EXTRACT(YEAR FROM s.date)                                    AS year

FROM spend_agg s
LEFT JOIN users_agg u
  ON s.date = u.date AND s.channel = u.channel AND s.geo = u.geo
LEFT JOIN users_total t
  ON s.date = t.date AND s.channel = t.channel AND s.geo = t.geo
ORDER BY s.date, s.channel, s.geo, u.device_os
