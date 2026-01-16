-- =====================================================================
-- Case Study: Foodie-Fi (8 Week SQL Challenge)
-- Author: Svetlana Stepanova
-- Purpose: Answer all business questions related to Foodie-Fi subscriptions.
-- Description: 
--  - Part A: Customer Journey
--      Analyze the onboarding journey of the sample customers using subscription data.
--  - Part B: Data Analysis Questions
--      Answer 11 questions related to customer counts, plan distributions, churn,
--      upgrades/downgrades, and timeline metrics.
--  - Part C: Challenge Payment Question
--      Build a payments table for 2020 simulating monthly and annual payments,
--      accounting for plan upgrades and churns.
--
--  - Tools: MySQL
-- =====================================================================

-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions 
-- table, write a brief description about each customer's onboarding journey.

-- Try to keep it as short as possible - you may also want to run some sort of join to 
-- make your explanations a bit easier!

WITH dates AS (
    SELECT *,
           LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_date,
           LEAD(plan_id)   OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan
    FROM subscriptions_example
),

dates_plan AS (
    SELECT *,
           CASE 
               WHEN next_date IS NOT NULL THEN TIMESTAMPDIFF(DAY, start_date, next_date)
               ELSE NULL 
           END AS date_diff,
           (SELECT plan_name 
            FROM plans p 
            WHERE p.plan_id = d.next_plan) AS next_plan_name
    FROM dates d
    ORDER BY customer_id, start_date
)

SELECT customer_id, 
       MIN(start_date) AS start_date,
       GROUP_CONCAT(plan_name ORDER BY start_date) AS plans,
       GROUP_CONCAT(CONCAT(date_diff, ' days before ', next_plan_name) 
                    ORDER BY start_date) AS days_difference
FROM dates_plan
JOIN plans
USING(plan_id)
GROUP BY customer_id
ORDER BY customer_id, start_date;


-- B. Data Analysis Questions
-- 1 How many customers has Foodie-Fi ever had?
-- 2 What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
-- 3 What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
-- 4 What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
-- 5 How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
-- 6 What is the number and percentage of customer plans after their initial free trial?
-- 7 What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
-- 8 How many customers have upgraded to an annual plan in 2020?
-- 9 How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- 10 Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- 11 How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

-- 1 How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) as all_customers
FROM subscriptions;

-- 2 What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT DATE_FORMAT(start_date, '%Y-%m-01') AS month,
       MONTHNAME(start_date) AS month_name,
       COUNT(plan_id) AS trial_count
FROM subscriptions 
WHERE plan_id = (SELECT plan_id FROM plans WHERE plan_name = 'trial')
GROUP BY month, month_name
ORDER BY month;

-- 3 What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT 
    (SELECT plan_name 
     FROM plans p 
     WHERE p.plan_id = s.plan_id) AS plan_name,
    COUNT(plan_id) AS plan_count
FROM subscriptions s
WHERE YEAR(start_date) > 2020
GROUP BY plan_name, plan_id
ORDER BY plan_id;

-- 4 What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT COUNT(DISTINCT customer_id) AS churned_customer_count,
       ROUND(
           COUNT(customer_id) * 100 / 
           (SELECT COUNT(DISTINCT customer_id) 
            FROM subscriptions), 
           1
       ) AS churned_customer_percentage
FROM subscriptions
JOIN plans
USING(plan_id)
WHERE plan_name = 'churn';
 
 -- 5 How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
 
CREATE TEMPORARY TABLE next_subscriptions AS
    SELECT customer_id, 
           plan_name, 
           start_date, 
           LEAD(plan_name) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan,
           LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_date,
           FIRST_VALUE(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS first_date,
           LAG(plan_name) OVER (PARTITION BY customer_id ORDER BY start_date) AS past_plan,
           LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS past_date
    FROM subscriptions 
    JOIN plans
    USING(plan_id);

SELECT COUNT(DISTINCT customer_id) AS customer_number,
       CONCAT(ROUND(COUNT(DISTINCT customer_id)*100/(SELECT COUNT(DISTINCT customer_id) 
                                                     FROM subscriptions), 0), '%') AS customer_percentage
FROM next_subscriptions
WHERE plan_name = 'trial' AND next_plan = 'churn';
  
    -- 6 What is the number and percentage of customer plans after their initial free trial?
  
SELECT next_plan,
       COUNT(next_plan) AS plan_count,
       CONCAT(
           ROUND(
               COUNT(next_plan) * 100 / (
                   SELECT COUNT(plan_id) 
                   FROM subscriptions
                   WHERE plan_id = (
                       SELECT plan_id 
                       FROM plans 
                       WHERE plan_name = 'trial'
                   )
               ), 1
           ), '%'
       ) AS plan_percent
FROM next_subscriptions
WHERE plan_name = 'trial'
GROUP BY next_plan
ORDER BY plan_count DESC;
 
 -- 7 What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

SELECT 
    plan_name,
    COUNT(customer_id) AS customer_count,
    CONCAT(
        ROUND(
            COUNT(customer_id) * 100 / (SUM(COUNT(customer_id)) OVER()),
            1
        ),
        '%'
    ) AS customer_percent
FROM next_subscriptions
WHERE start_date <= '2020-12-31'
  AND (next_date > '2020-12-31' OR next_date IS NULL)
GROUP BY plan_name
ORDER BY customer_count DESC;

-- 8 How many customers have upgraded to an annual plan in 2020?

SELECT 
    next_plan,
    COUNT(DISTINCT customer_id) AS customers_count
FROM next_subscriptions
WHERE next_plan = 'pro annual'
  AND YEAR(next_date) = 2020;

-- 9 How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

SELECT 
    ROUND(
        AVG(
            TIMESTAMPDIFF(DAY, first_date, start_date)
        ), 
        1
    ) AS average_days,
    COUNT(customer_id) AS customer_count
FROM next_subscriptions
WHERE plan_name = 'pro annual';

-- 10 Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

WITH breakdown AS (
    SELECT *,
           TIMESTAMPDIFF(DAY, first_date, start_date) AS days,
           FLOOR(TIMESTAMPDIFF(DAY, first_date, start_date)/30) AS breakdown
    FROM next_subscriptions
    WHERE plan_name = 'pro annual'
)

SELECT CONCAT(30*(breakdown), '-', 30*(breakdown+1)) AS breakdown_group,
       ROUND(AVG(days),1) AS average_days,
       COUNT(customer_id) AS customers_count
FROM breakdown
GROUP BY breakdown, breakdown_group
ORDER BY breakdown;
 
-- 11 How many customers downgraded from a pro monthly to a basic monthly plan in 2020?


SELECT 
    COUNT(customer_id) as customers_count
FROM next_subscriptions
WHERE plan_name = 'pro monthly' 
  AND next_plan = 'basic monthly'
  AND YEAR(next_date) = 2020;

-- C. Challenge Payment Question
--  The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

-- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-- once a customer churns they will no longer make payments


WITH RECURSIVE months_cte AS (
    SELECT customer_id, plan_name, start_date, next_plan, next_date, first_date, past_plan, past_date, price,
           start_date AS payment_date,
           CASE 
               WHEN plan_name IN ('pro monthly', 'pro annual') AND past_plan = 'basic monthly'
               THEN price - (SELECT price FROM plans p WHERE p.plan_name = past_plan)
               ELSE price 
           END AS amount
    FROM next_subscriptions s
    JOIN plans 
    USING(plan_name)
    WHERE plan_name IN ('basic monthly', 'pro monthly', 'pro annual')
  
    UNION ALL
  
    SELECT customer_id, plan_name, start_date, next_plan, next_date, first_date, past_plan, past_date, price, 
           CASE 
               WHEN plan_name IN ('basic monthly', 'pro monthly')
               THEN DATE_ADD(payment_date, INTERVAL 1 MONTH)
               ELSE DATE_ADD(payment_date, INTERVAL 1 YEAR) 
           END AS payment_date,
           price AS amount
    FROM months_cte 
    WHERE  (next_date IS NOT NULL AND
            DATE_ADD(payment_date, 
                     INTERVAL CASE 
                                  WHEN plan_name IN ('basic monthly', 'pro monthly') THEN 1
                                  WHEN plan_name = 'pro annual' THEN 12
                              END MONTH) < next_date
            AND payment_date < '2020-12-01') 
       OR (next_date IS NULL AND payment_date < '2020-12-01')
)

SELECT customer_id, plan_id, plan_name, payment_date, amount,
       ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY payment_date) AS payment_order
FROM months_cte
JOIN plans
USING(plan_name)
WHERE YEAR(payment_date) = 2020
ORDER BY customer_id, payment_date
LIMIT 20;
