WITH
  device_revenue AS (  -- revenue by device
    SELECT
      sp.continent,
      SUM(p.price) AS revenue,
      SUM(CASE WHEN sp.device = 'mobile' THEN p.price END)
        AS revenue_from_mobile,
      SUM(CASE WHEN sp.device = 'desktop' THEN p.price END)
        AS revenue_from_desktop
    FROM
      `DA.order` AS o
    JOIN
      `DA.product` AS p
      ON
        o.item_id = p.item_id
    JOIN
      `DA.session` AS s
      ON o.ga_session_id = s.ga_session_id
    JOIN
      `DA.session_params` AS sp
      ON
        o.ga_session_id = sp.ga_session_id
    GROUP BY
      sp.continent
  ),
  acc_and_session AS (  -- count accounts and sessions
    SELECT
      sp.continent,
      COUNT(DISTINCT ac.id) AS Account_Count,
      COUNT(DISTINCT CASE WHEN is_verified = 1 THEN ac.id END)
        AS Verified_Account,
      COUNT(DISTINCT s.ga_session_id) AS Session_Count
    FROM
      `DA.session` AS s
    LEFT JOIN
      `DA.account_session` AS acs
      ON
        s.ga_session_id = acs.ga_session_id
    LEFT JOIN
      `DA.account` AS ac
      ON
        acs.account_id = ac.id
    LEFT JOIN
      `DA.session_params` AS sp
      ON
        s.ga_session_id = sp.ga_session_id
    GROUP BY sp.continent
  )
SELECT
  device_revenue.continent AS Continent,
  ROUND(revenue, 2) AS Revenue,
  ROUND(revenue_from_mobile, 2) AS `Revenue from Mobile`,
  ROUND(revenue_from_desktop, 2) AS ` Revenue from Desktop`,
  ROUND(revenue / SUM(revenue) OVER () * 100, 2) AS `% Revenue from Total`,
  Account_Count AS `Account Count`,
  Verified_Account AS `Verified Account`,
  Session_Count AS `Session Count`
FROM
  acc_and_session
LEFT JOIN
  device_revenue
  ON
    acc_and_session.continent = device_revenue.continent
ORDER BY
  Revenue DESC
