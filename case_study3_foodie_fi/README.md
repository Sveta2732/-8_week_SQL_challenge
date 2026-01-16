# 🥘 Case 03 — Foodie-Fi
This case demonstrates my ability to analyze subscription data, use window and recursive functions, and derive actionable business insights.
## 📖 Business Context
Foodie-Fi is a subscription-based service offering multiple plans: trial, basic monthly, pro monthly, pro annual, and churn.  
The company wants to understand customer behavior to make data-driven decisions, including:  
- Customer onboarding journeys  
- Plan upgrades and downgrades  
- Churn rates and patterns  
- Payment timings and amounts  

This case study focuses on analyzing the subscription data to answer business questions about customer behavior and financial flows.

![Case Study Design](https://8weeksqlchallenge.com/images/case-study-designs/3.png)

---

## 🛠 SQL Concepts & Functions Used
This case demonstrates the following SQL skills and techniques used in the Foodie-Fi analysis:

- **Joins** ((`JOIN ... USING`, `JOIN ... ON`)) to combine subscription and plan data  
- **Window functions** (`LEAD`, `LAG`, `ROW_NUMBER`, `FIRST_VALUE`, `SUM(...) OVER()`) to analyze sequences and order of subscriptions  
- **CTEs / Recursive CTEs** (`WITH`, `WITH RECURSIVE`) to structure queries and simulate payments over time  
- **Temporary tables** (`CREATE TEMPORARY TABLE`) — store intermediate results for complex calculations or transformations  
- **Aggregation & GROUP BY** (`COUNT`, `SUM`, `AVG`, `GROUP_CONCAT`) for metrics, percentages, and summary tables  
- **CASE WHEN** to implement conditional logic (e.g., adjusting payment amounts)  
- **Date functions** (`TIMESTAMPDIFF`, `DATE_ADD`, `YEAR`, `DATE_FORMAT`) to calculate intervals and extract date components  
- **String functions** (`CONCAT`) to format output text like “days before next plan”  
- **ORDER BY / LIMIT** to control output order and size  

These concepts were applied to translate business questions into SQL queries and extract meaningful business insights.
###  Entity Relationship Diagram (ERD)
![Entity Relationship Diagram](https://8weeksqlchallenge.com/images/case-study-3-erd.png)
---


## 🛠 Tools

- **MySQL**

---


## ❓ Questions & Solutions

### A. Customer Journey
**Question:** 
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

**Solution:**
To clearly visualize the onboarding journey of 8 sample customers, I decided to create **a single table** that shows:  

- All the plans they switched through, in chronological order (`GROUP_CONCAT`),  
- The number of days before each transition to the next plan (`GROUP_CONCAT` with calculated day differences).  

This way, the table provides a **detailed view of each customer's journey** in one glance.  

Steps I followed:

1. **Created a CTE (`dates`)** where, for each row, the next plan and its start date are calculated using the window function `LEAD()`. If there is no next plan, the value is `NULL`.  
2. **Extended the CTE (`dates_plan`)** to calculate the difference in days between the current plan and the next plan using `TIMESTAMPDIFF()`.  
3. **Aggregated the information per customer** using `GROUP_CONCAT` to show the sequence of plans and the corresponding day differences in a single row per customer.  

This approach allows the onboarding journey of each customer to be **fully visible and easily interpretable** in one table.

```SQL
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
```

**Output:**

| customer_id | start_date  | plans                           | days_difference                          |
|------------:|------------|--------------------------------|-----------------------------------------|
| 1           | 2020-08-01 | trial,basic monthly             | 7 days before basic monthly             |
| 2           | 2020-09-20 | trial,pro annual                | 7 days before pro annual                |
| 11          | 2020-11-19 | trial,churn                     | 7 days before churn                      |
| 13          | 2020-12-15 | trial,basic monthly,pro monthly | 7 days before basic monthly, 97 days before pro monthly |
| 15          | 2020-03-17 | trial,pro monthly,churn         | 7 days before pro monthly, 36 days before churn |
| 16          | 2020-05-31 | trial,basic monthly,pro annual  | 7 days before basic monthly, 136 days before pro annual |
| 18          | 2020-07-06 | trial,pro monthly               | 7 days before pro monthly               |
| 19          | 2020-06-22 | trial,pro monthly,pro annual    | 7 days before pro monthly, 61 days before pro annual |

**Insights:**

Based on the table above, we can observe the following patterns from the onboarding journey of the 8 sample customers:  

Stage 1 — Trial Plan
- All customers **started with the trial plan** and stayed on it for **7 days** before switching to another plan.  

Stage 2 — First Plan Transition 
- Out of 8 customers:  
  - **1 churned immediately** after the trial.  
  - **1 subscribed to an annual plan**.  
  - The remaining customers chose **monthly plans**, roughly evenly split between Basic and Pro.  
  

Stage 3 — Second Plan Transition / Upgrades
  - **1 customer churned after a month** of using a paid plan.
- About **half of the remaining customers switched to a second paid plan**, upgrading to more premium (Pro) versions.  
- The **second transition** occurred **after 97–136 days**, roughly 3–4 months of using the first paid plan.

✅ In summary:  
- **2 out of 8 customers churned** (one after trial, one after a month).  
- The remaining customers **continued using the service**, with **about half upgrading** to more premium plans **after several months**.

These insights could help the business understand customer retention and upgrade patterns, which is useful for marketing or product decisions

### B. Data Analysis Questions
**Question:** 1. How many customers has Foodie-Fi ever had?

**Solution:**
To count all customers, we simply use `COUNT(DISTINCT customer_id)`.

```sql
SELECT COUNT(DISTINCT customer_id) AS all_customers
FROM subscriptions;
```
**Output:**
| all_customers |
|---------------|
| 1000          |

**Insights:**

There are 1,000 customers in total in the dataset

---
**Question:** 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

**Solution:**

- `DATE_FORMAT` was used to convert each start_date to the first day of the month, standardizing dates for monthly aggregation.  
- `MONTHNAME` was applied to make the month more readable in the output.  
- The number of subscriptions per month was counted using `GROUP BY`.  
- Results were sorted by month number to present months in chronological order.  
- A **subquery in the `WHERE` clause** was used to filter for *trial subscriptions*, retrieving the correct `plan_id`.
```SQL
SELECT DATE_FORMAT(start_date, '%Y-%m-01') AS month,
       MONTHNAME(start_date) AS month_name,
       COUNT(plan_id) AS trial_count
FROM subscriptions 
WHERE plan_id = (SELECT plan_id FROM plans WHERE plan_name = 'trial')
GROUP BY month, month_name
ORDER BY month;
```

**Output:**
| month       | month_name | trial_count |
|------------|------------|------------|
| 2020-01-01 | January    | 88         |
| 2020-02-01 | February   | 68         |
| 2020-03-01 | March      | 94         |
| 2020-04-01 | April      | 81         |
| 2020-05-01 | May        | 88         |
| 2020-06-01 | June       | 79         |
| 2020-07-01 | July       | 89         |
| 2020-08-01 | August     | 88         |
| 2020-09-01 | September  | 87         |
| 2020-10-01 | October    | 79         |
| 2020-11-01 | November   | 75         |
| 2020-12-01 | December   | 84         |

**Insights:** 

Each month, **70–90 customers** started a trial plan, showing steady engagement throughout 2020. 

---
**Question:** 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

**Solution:**

Since the subscriptions table only contains `plan_id`, the `correlated subquery` is used to fetch the corresponding `plan_name` from the plans table. Then, the results are grouped by plan and counted using `COUNT()` to show the number of subscriptions per plan.
```SQL
SELECT 
    (SELECT plan_name 
     FROM plans p 
     WHERE p.plan_id = s.plan_id) AS plan_name,
    COUNT(plan_id) AS plan_count
FROM subscriptions s
WHERE YEAR(start_date) > 2020
GROUP BY plan_name, plan_id
ORDER BY plan_id;
```
**Output:**
| plan_name     | plan_count |
| ------------- | ---------- |
| basic monthly | 8          |
| pro monthly   | 60         |
| pro annual    | 63         |
| churn         | 71         |

**Insights:**

Most post-2020 subscriptions are Pro plans (Monthly and Annual), indicating high interest in premium options. Basic Monthly is rare, and Churn is notable, showing a significant number of users leaving after trial or paid plans.

---

**Question:** 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

**Solution:**

- I first join the subscriptions table with plans to access the plan_name. 
- Then, I filter only the customer events where `plan_name = 'churn'`. 
- To get the number of unique churned customers, I use `COUNT(DISTINCT)`. 
- For the churn percentage, I divide this count by the total number of distinct customers, retrieved via a subquery, and round the result to one decimal place.

```SQL
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
```
**Output:**
| churned_customer_count | churned_customer_percentage |
|-----------------------|----------------------------|
| 307                   | 30.7%                      |

**Insights:**

About 31% of customers churned, showing a significant portion left the service.

---

**Question:**   5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
 
**Solution:**

A temporary table   `(next_subscriptions)` was created to calculate each customer’s next plan and start date using the window function `LEAD()`. Additionally, the previous plan and its start date are captured using `LAG()`, and the first date of service for each customer is captured with `FIRST_VALUE()`. This allows a full view of each customer’s subscription history within the session. 

This temporary table approach was chosen because window functions  are frequently used throughout the case study, and this table can be reused in subsequent questions, making the analysis efficient and consistent across the session.

- The table is joined with the plans table to access plan names. 
- Using this temporary table, the dataset is filtered to identify customers whose current plan was "trial" and whose next plan was "churn". 
- The number of these customers is counted and divided by the total number of distinct customers (obtained via a subquery) to calculate the percentage of users who churned immediately after the trial.


```SQL
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
```
**Output:**
| customer_number | customer_percentage |
| --------------- | ------------------- |
| 92              | 9                   |

**Insights:**

Out of all customers, 9% churned immediately after their trial.

---

**Question:** 6. What is the number and percentage of customer plans after their initial free trial?
  
**Solution:**

The temporary table `next_subscriptions`, created in earlier steps using window functions, was utilized to analyze customer behavior immediately after the trial period.

Analysis steps:

- Filtered the table to include only rows where the current plan is "trial".

- Grouped the data by next plan to count the number of customers switching to each plan.

- Calculated the percentage of customers for each next plan relative to all trial subscriptions using a nested subquery.

- Sorted results in descending order by customer count for clarity.


```SQL
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
```
**Output:**
| next_plan     | plan_count | plan_percent |
| ------------- | ---------- | ------------ |
| basic monthly | 546        | 54.6%        |
| pro monthly   | 325        | 32.5%        |
| churn         | 92         | 9.2%         |
| pro annual    | 37         | 3.7%         |


**Insights:**

After the trial, most customers continued with monthly plans, with Basic monthly being the most popular. Transition to annual plans was less common, and around 10% of customers churned immediately after the trial.

---
**Question:** 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

**Solution:**

A previously created temporary table `next_subscriptions` was used for this analysis.
- The data was filtered to include only subscriptions active on 2020-12-31, meaning:
     - the current plan started on or before this date, and

    - there was either no next plan or the next plan started after this date.

- Results were grouped by plan_name to calculate the number of customers on each plan.

- The percentage breakdown was calculated using a window aggregation over the total customer count.

- Finally, results were sorted in descending order by customer count to highlight the most popular plans at the end of 2020.
```SQL
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
```
**Output:**

| plan_name       | customer_count | customer_percent |
|-----------------|----------------|------------------|
| pro monthly     | 326            | 32.6%            |
| churn           | 236            | 23.6%            |
| basic monthly   | 224            | 22.4%            |
| pro annual      | 195            | 19.5%            |
| trial           | 19             | 1.9%             |

**Insights:**

As of 2020-12-31, the largest share of customers were on Pro monthly plans, followed by Basic monthly and Pro annual. Nearly one quarter of customers had churned, while only a small fraction remained on the trial plan, indicating that most users had already made a subscription decision by the end of 2020.

---
**Question:** 8 How many customers have upgraded to an annual plan in 2020?

**Solution:**

This question was straightforward to answer using the temporary table `next_subscriptions`, which already contains information about previous and next plans calculated with window functions.

For this analysis:

- The data was filtered to include only records where the next plan is pro annual.

- An additional filter was applied to ensure the upgrade occurred in 2020 using YEAR(next_date) = 2020.

- Finally, the number of distinct customers was counted to obtain the result.

This approach is efficient because the upgrade logic is already precomputed in the temporary table, allowing the question to be answered with a simple filter and aggregation.

```SQL
SELECT 
    next_plan,
    COUNT(DISTINCT customer_id) AS customers_count
FROM next_subscriptions
WHERE next_plan = 'pro annual'
  AND YEAR(next_date) = 2020;
```
**Output:**
| next_plan  | customers_count |
| ---------- | --------------- |
| pro annual | 195             |

**Insights:**

A total of 195 customers upgraded to the Pro Annual plan in 2020, indicating a strong level of long-term commitment.

---
**Question:** 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?



**Solution:**

The previously created temporary table `next_subscriptions` was reused for this analysis.

- Records were filtered to include only customers whose current plan is Pro Annual.

- For each customer, the number of days to upgrade was calculated using `TIMESTAMPDIFF` between:

   - the start date of the Pro Annual plan, and

    - the customer’s first-ever subscription date, obtained earlier using the window function `FIRST_VALUE`.

- The average number of days was then computed across all filtered customers using `AVG`.

```SQL
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
```
**Output:**
| average_days | customer_count |
| -----------: | -------------: |
|        104.6 |            258 |

**Insights:**

On average, customers take about 105 days (≈3.5 months) from joining Foodie-Fi to upgrading to the Pro Annual plan. This suggests that most users spend several months on trial or monthly plans before committing to a long-term subscription.

---
**Question:** 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

**Solution:**
To answer this question, a temporary CTE breakdown was created:

- Filtered the `next_subscriptions` table to include only rows where the plan is pro annual.

- Calculated the difference in days between the start of the annual plan and the customer's first day using `TIMESTAMPDIFF()`.

- Divided the result by 30 and applied `FLOOR()` to assign each customer to a 30-day period category (breakdown).

In the main query:

- Data was grouped by these breakdown categories.

- `CONCAT()` and simple arithmetic were used to define the **left-inclusive, right-exclusive boundaries** of each period.

- Counted the number of customers in each group.

- Calculated the average number of days it took to upgrade within each 30-day period.

This approach clearly shows the distribution and timing of upgrades to the annual plan

```SQL
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
```
**Output:**
| breakdown_group | average_days | customers_count |
| --------------- | ------------ | --------------- |
| 0-30            | 9.5          | 48              |
| 30-60           | 41.8         | 25              |
| 60-90           | 70.9         | 33              |
| 90-120          | 99.8         | 35              |
| 120-150         | 133.0        | 43              |
| 150-180         | 161.5        | 35              |
| 180-210         | 190.3        | 27              |
| 210-240         | 224.3        | 4               |
| 240-270         | 257.2        | 5               |
| 270-300         | 285.0        | 1               |
| 300-330         | 327.0        | 1               |
| 330-360         | 346.0        | 1               |

**Insights:**
Most customers upgraded to an annual plan within 0–210 days (up to ~7 months) from starting the service. Very few customers upgraded later in the year.

---
**Question:** 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

**Solution:**

The answer to this question is straightforward using the temporary table `next_subscriptions`.

- The dataset was filtered with three conditions:

    - The current plan is 'pro monthly'.

     - The next plan is 'basic monthly'.

     - The transition occurred in the year 2020.

After applying these filters, the number of customers meeting all three criteria was counted.
```SQL
SELECT 
    COUNT(customer_id) as customers_count
FROM next_subscriptions
WHERE plan_name = 'pro monthly' 
  AND next_plan = 'basic monthly'
  AND YEAR(next_date) = 2020;
```
**Output:**
| customers_count |
|----------------|
| 0              |

**Insights:**

No customers downgraded from a Pro Monthly to a Basic Monthly plan in 2020, indicating that downgrades from higher-tier monthly plans were extremely rare or nonexistent during that period.

---

###  C. Challenge Payment Question
**Question:** 
The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-  once a customer churns they will no longer make payments
**Solution:**

This task was the most challenging in the case because it required the use of a recursive CTE, which I had not practiced before.

Steps I followed:

- Created the `recursive CTE` months_cte:

     - Joined the previously created next_subscriptions temporary table with plans.

    - Filtered to include only paid subscriptions.

    - Selected almost all columns from the original table to compare intermediate outputs with the original data for each customer and check for potential errors.

    - Set the initial payment date as the start date of each subscription.

    - Calculated the payment amount using a `CASE` statement, taking into account potential deductions for plan upgrades.

- Recursive step (`UNION ALL`):

    - Carried forward the same columns.

    - Used a `CASE` statement to increment the payment date by 1 month for monthly plans or 1 year for annual plans.

    - Set the payment amount for subsequent payments (only the first payment could differ if there was an adjustment).

- Stop condition for recursion:

    - The recursion stops if adding the interval would exceed the start date of the next plan or the end of the year (2020-12-31).

Final selection:

- Filtered records to include only payments in 2020.

- Selected relevant columns.

- Assigned a payment order for each customer using `ROW_NUMBER()` window function.

```SQL
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
```
**Output:**
| customer_id | plan_id | plan_name     | payment_date | amount | payment_order |
| ----------: | ------: | ------------- | ------------ | -----: | ------------- |
|           1 |       1 | basic monthly | 2020-08-08   |    9.9 | 1             |
|           1 |       1 | basic monthly | 2020-09-08   |    9.9 | 2             |
|           1 |       1 | basic monthly | 2020-10-08   |    9.9 | 3             |
|           1 |       1 | basic monthly | 2020-11-08   |    9.9 | 4             |
|           1 |       1 | basic monthly | 2020-12-08   |    9.9 | 5             |
|           2 |       3 | pro annual    | 2020-09-27   |  199.0 | 1             |
|           3 |       1 | basic monthly | 2020-01-20   |    9.9 | 1             |
|           3 |       1 | basic monthly | 2020-02-20   |    9.9 | 2             |
|           3 |       1 | basic monthly | 2020-03-20   |    9.9 | 3             |
|           3 |       1 | basic monthly | 2020-04-20   |    9.9 | 4             |
|           3 |       1 | basic monthly | 2020-05-20   |    9.9 | 5             |
|           3 |       1 | basic monthly | 2020-06-20   |    9.9 | 6             |
|           3 |       1 | basic monthly | 2020-07-20   |    9.9 | 7             |
|           3 |       1 | basic monthly | 2020-08-20   |    9.9 | 8             |
|           3 |       1 | basic monthly | 2020-09-20   |    9.9 | 9             |
|           3 |       1 | basic monthly | 2020-10-20   |    9.9 | 10            |
|           3 |       1 | basic monthly | 2020-11-20   |    9.9 | 11            |
|           3 |       1 | basic monthly | 2020-12-20   |    9.9 | 12            |
|           4 |       1 | basic monthly | 2020-01-24   |    9.9 | 1             |
|           4 |       1 | basic monthly | 2020-02-24   |    9.9 | 2             |

**Insights:**

**Only the first 20 records are shown**.
Comparison with the sample output from the 8 Week SQL Challenge confirms that the code works correctly, generating the proper payment_date and calculating amount according to the challenge rules.

**Observation:** The challenge text does not specify rules for plan downgrades; this could be enhanced for more realistic scenarios and to cover all edge cases.

---

## 🔹 Overall Summary

In general, this case was fairly simple and straightforward. Most of the tasks could be solved using window functions and the temporary table (next_subscriptions). The final challenge introduced a recursive CTE (months_cte) to model recurring payments, which I had not practiced before.

- A **temporary table** was used to calculate each customer’s next plan, previous plan, and first subscription date, serving as the foundation for most queries.

- **Window functions** (`LEAD`, `LAG`, `FIRST_VALUE`, `ROW_NUMBER`) and aggregations (`COUNT`, `GROUP_CONCAT`, `AVG`) were used extensively to analyze customer journeys, churn, plan upgrades/downgrades, and payment behavior.

- The **recursive table** was used to calculate recurring payments, taking into account start dates, plan changes, and plan-specific rules.

In summary, this case reinforced analytical thinking in SQL, the use of window and recursive functions, and the ability to derive business insights from subscription data—all highly relevant skills for a junior data analyst or data scientist role.