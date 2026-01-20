# 🍕 Case 02 — Pizza Runner

## 📖 Business Context

This case study focuses on **Pizza Runner**, a startup pizza delivery business by Danny. The goal is to use SQL analysis to understand customer orders, runner performance, and delivery operations in order to make data-driven decisions and improve efficiency.

The key questions are grouped by topic and ordered from simple to more complex:

- **A. Pizza Metrics**  
  *Example:* How many pizzas were ordered?

- **B. Runner and Customer Experience**  
  *Example:* What was the average time (in minutes) it took for each runner to arrive at the Pizza Runner HQ to pick up an order?

- **C. Ingredient Optimisation**  
  *Example:* What was the most commonly added extra ingredient across all orders?

- **D. Pricing and Ratings**  
  *Example:* If a Meat Lovers pizza costs $12 and a Vegetarian pizza costs $10 (with no extras fees), how much revenue has Pizza Runner made so far?

- **E. Bonus DML Challenges**  
  *Example:* How would you modify the database schema and insert data if Pizza Runner expanded the menu with a new pizza type?

![Case Study Design](https://8weeksqlchallenge.com/images/case-study-designs/2.png)

## 🛠 SQL Concepts & Functions Used

This case demonstrates the following SQL skills and techniques applied to analyze **Pizza Runner** data:

- **Joins** (`JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `USING`) to combine multiple tables and create a unified dataset for analysis.  

- **Window functions** (`ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`) to rank, number, or order rows within partitions of data for comparison or sequencing.  

- **CTEs (`WITH`)** to structure queries into readable, reusable steps and simplify complex transformations.  

- **Aggregation & GROUP BY** (`COUNT`, `SUM`, `AVG`, `ROUND`, `DISTINCT`, `GROUP_CONCAT`) to summarize data, compute totals, averages, frequencies, and compile multiple values into a single row.  

- **CASE WHEN** to implement conditional logic, create calculated columns, or handle different scenarios in one query.  

- **Date & Time functions** (`TIMESTAMPDIFF`, `DATE_ADD`, `HOUR()`, `DAYOFWEEK()`, `DAYNAME`) to calculate intervals, extract components, or filter based on dates and times.  

- **COALESCE** to handle missing or NULL values and provide default outputs.  

- **String functions** (`CONCAT`, `GROUP_CONCAT`) to combine text or create human-readable results from multiple rows. 

- **JSON functions** (`JSON_ARRAY`, `JSON_TABLE`, `REPLACE`) to transform comma-separated values into arrays, extract individual elements, and expand them into separate rows for analysis.

- **Temporary Tables** (`CREATE TEMPORARY TABLE`) to store intermediate results for further analysis or complex transformations.  

- **DML statements** (`INSERT`, `DROP TABLE`) to manipulate and simulate data for testing or scenario analysis.  

- **ORDER BY / LIMIT** to sort query results and control which rows are returned.   

These techniques were applied to answer questions related to pizza metrics, runner and customer experience, ingredient optimisation, pricing and ratings, and bonus scenarios, providing actionable insights for operational and business decisions.

## 📊 Datasets

The case uses several key datasets from the **pizza_runner** database schema, each capturing a different part of the pizza delivery business:

- **`runners`** — contains information about each delivery runner and their registration date.  
- **`customer_orders`** — records pizza orders placed by customers, with one row per pizza item, including pizza type, extra toppings, and exclusions.  
- **`runner_orders`** — holds delivery information such as which runner handled the order, pickup time, distance travelled, delivery duration, and cancellation status.  
- **`pizza_names`** — lists the available pizza types (e.g., Meat Lovers, Vegetarian) with corresponding IDs.  
- **`pizza_recipes`** — defines the standard set of toppings associated with each pizza type.  
- **`pizza_toppings`** — provides a lookup of topping IDs to topping names, used to interpret recipe and order customization values.  

###  Entity Relationship Diagram (ERD)
![Entity Relationship Diagram](https://raw.githubusercontent.com/Sveta2732/-8_week_SQL_challenge/ce1411e1bdab34c69fea12b3af886a2052673b16/case_study2%20_pizza_runner/ERD.png)
---


## 🛠 Tools

- **MySQL**

---

## 🧹 Data Cleaning & Preparation

Before analyzing the Pizza Runner datasets, several data cleaning steps were applied to ensure accuracy and consistency:

- **Normalize null or missing values**:  
  - Set empty strings, `'null'`, or `'NaN'` in `customer_orders.extras` and `customer_orders.exclusions` to `NULL`.  
  - Set invalid or `'null'` values in `runner_orders.pickup_time`, `runner_orders.distance`, `runner_orders.duration`, and `runner_orders.cancellation` to `NULL`.  

- **Extract numeric values**:  
  - Use regular expressions to retain only numeric values from `runner_orders.distance` and `runner_orders.duration`.

- **Adjust data types**:  
  - Convert `runner_orders.distance` to `FLOAT` and `runner_orders.duration` to `INT` for proper numerical calculations.

These steps ensure that subsequent queries on orders, deliveries, and toppings produce **reliable and accurate insights**.

---
## ❓ Questions & Solutions
### A. Pizza Metrics
**Question:** 1. How many pizzas were ordered?

**Solution:**

I used `COUNT` to calculate the total number of pizzas ordered.

```sql

SELECT 
    COUNT(pizza_id) AS ordered 
FROM 
    customer_orders;
```
**Output:**

| ordered |
| ------- |
| 14      |


**Insights:**

A total of 14 pizzas were ordered across all customers, giving a quick overview of the overall pizza demand.

---

**Question:** 2 How many unique customer orders were made?

**Solution:**

I used COUNT(DISTINCT ...) to count the number of unique customer orders.

```sql
SELECT 
    COUNT(DISTINCT order_id) AS unique_orders
FROM 
    customer_orders;
```
**Output:**

| unique_orders |
|---------------|
| 10            |



**Insights:**

There were 10 unique customer orders in the dataset, indicating that while there may be multiple items per order. This can help understand customer activity and order frequency.

---

**Question:** 3. How many successful orders were delivered by each runner?

**Solution:**



```sql
SELECT 
    runner_id, 
    COUNT(order_id) AS successful_orders
FROM 
    runner_orders
WHERE 
    cancellation IS NULL
GROUP BY 
    runner_id
ORDER BY 
    runner_id;
```
**Output:**

| runner_id | successful_orders |
|-----------|-----------------|
| 1         | 4               |
| 2         | 3               |
| 3         | 1               |


**Insights:**

Runner 1 completed the most successful orders (4), followed by Runner 2 (3) and Runner 3 (1). This shows that performance varies among runners, which could help in evaluating efficiency or assigning workloads.

---
**Question:** 4. How many of each type of pizza was delivered?

**Solution:**

To answer this question, I combined customer orders with runner orders to analyze delivered pizzas.
- Joined `customer_orders` with `runner_orders` using `order_id`.
- Filtered out cancelled orders (cancellation `IS NULL`).
- Grouped the results by pizza type (`pizza_id`).
- Counted the number of pizzas using `COUNT`.
- Retrieved pizza names via a correlated subquery from the `pizza_names` table where `pizza_id` matches the main query (the table is small, so a subquery is efficient).


```sql
SELECT 
    (SELECT pizza_name 
     FROM pizza_names p
     WHERE o.pizza_id = p.pizza_id) AS pizza_name,
    COUNT(o.pizza_id) AS number_of_pizzas
FROM 
    customer_orders o
JOIN runner_orders r USING (order_id)
WHERE 
    r.cancellation IS NULL
GROUP BY 
    o.pizza_id
ORDER BY 
    o.pizza_id;
```
**Output:**

| pizza_name   | number_of_pizzas |
|-------------|-----------------|
| Meatlovers  | 9               |
| Vegetarian  | 3               |


**Insights:**

The Meatlovers pizza was the most popular, with 9 orders, while Vegetarian pizzas were ordered less frequently (3). This suggests customer preference leans towards meat-based options.

---
**Question:** 5. How many Vegetarian and Meatlovers were ordered by each customer?

**Solution:**

Used the `customer_orders` table.
- Grouped the data by `customer_id`.
- Created additional columns for Meatlovers and Vegetarian using `CASE WHEN`, assigning 1/0 based on pizza type.
- Counted the number of pizzas ordered using `SUM`.

```sql

SELECT 
    o.customer_id,
    SUM(CASE WHEN o.pizza_id = 1 THEN 1 ELSE 0 END) AS Meatlovers_pizza,
    SUM(CASE WHEN o.pizza_id = 2 THEN 1 ELSE 0 END) AS Vegetarian_pizza
FROM 
    customer_orders o
GROUP BY 
    o.customer_id
ORDER BY 
    o.customer_id;
```
**Output:**

| customer_id | Meatlovers_pizza | Vegetarian_pizza |
|------------|-----------------|-----------------|
| 101        | 2               | 1               |
| 102        | 2               | 1               |
| 103        | 3               | 1               |
| 104        | 3               | 0               |
| 105        | 0               | 1               |


**Insights:**

Most customers ordered more Meatlovers pizzas than Vegetarian, showing a clear preference for meat-based options. Customer 105 is the only one who ordered only a Vegetarian pizza, highlighting a smaller but existing demand for vegetarian choices.

---
**Question:** 6. What was the maximum number of pizzas delivered in a single order?

**Solution:**

Used the `customer_orders` dataset joined with `runner_orders`.
- Filtered out cancelled orders (`cancellation IS NULL`).
- Grouped the data by `order_id`.
-Counted the number of pizzas per order using `COUNT`.
- Sorted the results in descending order by the count and selected the top order using `LIMIT 1`

```sql
SELECT 
    order_id, 
    COUNT(pizza_id) AS number_of_pizzas
FROM 
    customer_orders
JOIN runner_orders USING(order_id)
WHERE 
    cancellation IS NULL
GROUP BY 
    order_id
ORDER BY 
    number_of_pizzas DESC
LIMIT 1;
```
**Output:**

| order_id | number_of_pizzas |
|----------|-----------------|
| 4        | 3               |


**Insights:**

The maximum number of pizzas delivered in a single order was 3 (order 4). This indicates that most orders were smaller, with 3 pizzas being the largest single transaction in the dataset.

---
**Question:** 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

**Solution:**

For clarity and convenience, I created an intermediate step and a main query.
- CTE / intermediate step:
    - As in previous questions, joined the two tables.
    - Filtered out cancelled orders.
    - Used `CASE WHEN` to define changed and unchanged columns and filled them with 1/0.
- Main query:
    - Grouped the data by customer.
    - Calculated the sum of 1s for changed and unchanged.

```sql
WITH changes AS (
    SELECT 
        order_id, 
        customer_id, 
        pizza_id, 
        CASE 
            WHEN exclusions IS NULL AND extras IS NULL THEN 0
            ELSE 1
        END AS changes,
        CASE 
            WHEN exclusions IS NULL AND extras IS NULL THEN 1
            ELSE 0
        END AS unchanged
    FROM 
        customer_orders
    JOIN runner_orders USING(order_id)
    WHERE 
        cancellation IS NULL
)

SELECT 
    customer_id, 
    SUM(changes) AS changed, 
    SUM(unchanged) AS unchanged
FROM 
    changes
GROUP BY 
    customer_id
ORDER BY 
    customer_id;

```
**Output:**

| customer_id | changed | unchanged |
|------------|---------|-----------|
| 101        | 0       | 2         |
| 102        | 0       | 3         |
| 103        | 3       | 0         |
| 104        | 2       | 1         |
| 105        | 1       | 0         |


**Insights:**

Some customers consistently ordered pizzas without changes (customers 101 and 102), while others frequently requested modifications (customer 103 had all pizzas changed). This highlights different customer preferences and the need to track customization requests.

---
**Question:** 8. How many pizzas were delivered that had both exclusions and extras?

**Solution:**

For clarity and convenience, I created a CTE and a main query to find pizzas that had both exclusions and extras.
- CTE / intermediate step (Identified orders that were successfully delivered.):
    - Joined the two tables and filtered out cancelled orders (`cancellation IS NULL`).
- Main query:
    - Used a `LEFT JOIN` to combine these delivered orders with `customer_orders`, ensuring only delivered orders are included.
    - Applied a `CASE WHEN` condition to mark orders that had both exclusions and extras with 1.
    - Summed the 1s to get the total number of pizzas with both modifications.

```sql
WITH successful_orders AS (
    SELECT 
        order_id
    FROM 
        runner_orders
    WHERE 
        cancellation IS NULL
)

SELECT 
    SUM(CASE 
            WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1
            ELSE 0
        END) AS both_changed
FROM 
    successful_orders
LEFT JOIN 
    customer_orders
USING(order_id);
```
**Output:**

| both_changed |
|--------------|
| 1            |


**Insights:**

Only 1 pizza had both exclusions and extras, showing that it is quite rare for customers to customize pizzas with both modifications simultaneously.

---
**Question:** 9. What was the total volume of pizzas ordered for each hour of the day?

**Solution:**

To analyze the total volume of pizzas ordered for each hour of the day, I grouped orders by hour.
- Used the `HOUR` function to extract the hour from order_time.
- Grouped the data by this hour.
- Counted the number of orders for each hour.
- Sorted the results by hour.

```sql
SELECT 
    HOUR(order_time) AS order_hour, 
    COUNT(*) 
FROM 
    customer_orders
GROUP BY 
    HOUR(order_time)
ORDER BY 
    HOUR(order_time);

```
**Output:**

| order_hour | total_pizzas |
|------------|--------------|
| 11         | 1            |
| 13         | 3            |
| 18         | 3            |
| 19         | 1            |
| 21         | 3            |
| 23         | 3            |


**Insights:**

The busiest hours for pizza orders were 13:00, 18:00, 21:00, and 23:00, each with 3 pizzas ordered. Early morning and late afternoon had fewer orders, suggesting peak ordering times align with lunch and evening meals.

---
**Question:** 10. What was the volume of orders for each day of the week?

**Solution:**

To analyze the volume of orders and pizzas for each day of the week, I grouped orders by day.
- Extracted `DAYNAME` and `DAYOFWEEK` from order_time.
- Grouped the data by day of the week.
- Counted the number of orders using `COUNT(DISTINCT)` and the number of pizzas using `COUNT()`.
- Sorted the results by the day number for presentation.

```sql
SELECT 
    DAYNAME(order_time) AS day_of_week, 
    COUNT(DISTINCT order_id) AS number_of_orders, 
    COUNT(pizza_id) AS number_of_pizzas
FROM 
    customer_orders
GROUP BY 
    DAYOFWEEK(order_time), 
    DAYNAME(order_time)
ORDER BY 
    DAYOFWEEK(order_time);
```
**Output:**

| day_of_week | number_of_orders | number_of_pizzas |
|------------|-----------------|-----------------|
| Wednesday  | 5               | 5               |
| Thursday   | 2               | 3               |
| Friday     | 1               | 1               |
| Saturday   | 2               | 5               |


**Insights:**

Wednesday had the highest number of orders (5), while Saturday, despite having fewer orders (2), had a high number of pizzas (5), indicating larger orders on that day. Fridays saw the lowest activity in both orders and pizzas.

---

### B. Runner and Customer Experience
**Question:** 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

**Solution:**

- Created an intermediate CTE dates to determine the signup week for each runner
    - Calculated the week number using the difference between registration_date and the reference start date 2021-01-01, divided into 7-day periods with `DATE_ADD`
- In the main query, grouped the data by week number
    - Constructed a readable week interval using `CONCAT` and date arithmetic based on the calculated week number
    - Counted the number of runners who signed up in each weekly period

```sql

WITH dates AS (
    SELECT 
        FLOOR((DATE_ADD(registration_date, INTERVAL 1 DAY) - DATE '2021-01-01') / 7) AS week_number,
        runner_id 
    FROM 
        runners
)

SELECT 
    week_number + 1 AS week_number, 
    CONCAT(
        DATE_ADD('2021-01-01', INTERVAL (week_number * 7) DAY), 
        ' - ', 
        DATE_ADD('2021-01-01', INTERVAL (week_number * 7 + 6) DAY)
    ) AS week_interval, 
    COUNT(runner_id) AS number_of_runners
FROM 
    dates 
GROUP BY 
    week_number 
ORDER BY 
    week_number;

```
**Output:**

| week_number | week_interval           | number_of_runners |
| ----------: | ----------------------- | ----------------: |
|           1 | 2021-01-01 – 2021-01-07 |                 2 |
|           2 | 2021-01-08 – 2021-01-14 |                 1 |
|           3 | 2021-01-15 – 2021-01-21 |                 1 |


**Insights:**

The majority of runners (2 out of 4) signed up in the first week, indicating stronger initial onboarding activity. Runner sign-ups slowed down in subsequent weeks, with only one new runner per week in weeks 2 and 3.

---
**Question:** 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

**Solution:**
- Created a CTE with `DISTINCT` order_id and order_time to count each order only once, avoiding overcounting when a single order has multiple pizzas.
- Joined the CTE with `runner_orders`.
- Filtered out cancelled orders
- Grouped by runners
- Calculated pickup time using `TIMESTAMPDIFF`
- Computed the average with `AVG`

```sql

WITH orders AS (
    SELECT DISTINCT 
        order_time, 
        order_id
    FROM 
        customer_orders
)

SELECT 
    runner_id,
    ROUND(
        AVG(TIMESTAMPDIFF(MINUTE, order_time, pickup_time)), 
        1
    ) AS average_arriving_time
FROM 
    runner_orders 
JOIN 
    orders 
USING (order_id)
WHERE 
    cancellation IS NULL
GROUP BY 
    runner_id
ORDER BY 
    runner_id;
```
**Output:**

| runner_id | average_arriving_time |
| --------- | --------------------- |
| 1         | 14.0                  |
| 2         | 19.7                  |
| 3         | 10.0                  |




**Insights:**

- Runner 3 is the fastest on average, arriving in 10 minutes.
- Runner 2 has the slowest average pickup time (19.7 minutes), which may indicate longer distances or availability issues.
- Runner 1 shows moderate performance, arriving in around 14 minutes on average.

---
**Question:** 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

**Solution:**

- First query – to show for each order the number of pizzas, total cooking time, and time per pizza
     - Created a CTE to count the number of pizzas for each order
    - In the main query, joined with runner_orders and filtered orders where pickup_time is not null (i.e., orders were not cancelled)
    - Selected for each order: number of pizzas, cooking time using `TIMESTAMPDIFF`, and time per pizza (total cooking time divided by number of pizzas, rounded using `ROUND`)

- Second query – to calculate the average cooking time of pizzas depending on the number of pizzas per order
    - Used the same CTE as in the first query to count pizzas per order
    - In the main query, joined with runner_orders and filtered orders where pickup_time is not null
    - Grouped by pizza_amount and calculated the average cooking time per group using `AVG`, rounded with `ROUND`

```sql

-- first
WITH pizza_number AS (
    SELECT 
        order_id, 
        order_time, 
        COUNT(pizza_id) AS pizza_amount
    FROM 
        customer_orders
    GROUP BY 
        order_id, 
        order_time
)

SELECT 
    order_id, 
    pizza_amount, 
    TIMESTAMPDIFF(MINUTE, order_time, pickup_time) AS cooking_time,
    ROUND(
        TIMESTAMPDIFF(MINUTE, order_time, pickup_time) / pizza_amount, 
        1
    ) AS time_per_pizza
FROM 
    runner_orders
JOIN 
    pizza_number
USING (order_id)
WHERE 
    pickup_time IS NOT NULL
ORDER BY pizza_amount, time_per_pizza;

-- second 
WITH pizza_number AS (
    SELECT 
        order_id, 
        order_time, 
        COUNT(pizza_id) AS pizza_amount
    FROM 
        customer_orders
    GROUP BY 
        order_id, 
        order_time
)

SELECT 
    pizza_amount, 
    ROUND(
        AVG(TIMESTAMPDIFF(MINUTE, order_time, pickup_time)), 
        1
    ) AS average_cooking_time
FROM 
    runner_orders
JOIN 
    pizza_number
USING (order_id)
WHERE 
    pickup_time IS NOT NULL
GROUP BY 
    pizza_amount
ORDER BY 
    pizza_amount;
```
**Output:**

| order_id | pizza_amount | cooking_time | time_per_pizza |
| -------- | ------------ | ------------ | -------------- |
| 1        | 1            | 10           | 10.0           |
| 2        | 1            | 10           | 10.0           |
| 5        | 1            | 10           | 10.0           |
| 7        | 1            | 10           | 10.0           |
| 8        | 1            | 20           | 20.0           |
| 10       | 2            | 15           | 7.5            |
| 3        | 2            | 21           | 10.5           |
| 4        | 3            | 29           | 9.7            |

| pizza_amount | average_cooking_time |
| ------------ | ---------------------- |
| 1            | 12.0                   |
| 2            | 18.0                   |
| 3            | 29.0                   |


**Insights:**

- In most single-pizza orders, it took 10 minutes to prepare, except for order 8, which took twice as long.
- For two-pizza orders, preparation time ranged from 15 to 21 minutes (i.e., 7.5 to 10.5 minutes per pizza).
- For three-pizza orders, it took almost 30 minutes (9.7 minutes per pizza).
- Orders with more pizzas tend to take longer to prepare overall.
- On average, a single pizza can be prepared in about 10 minutes, but sometimes it takes more or less (from 7.5 to 20 minutes).

---
**Question:** 4. What was the average distance travelled for each customer?

**Solution:**

Because one order can contain multiple pizzas and therefore multiple rows, counting each row would overcount the deliveries. To calculate correctly (the runner did not deliver the same order three times if it had three pizzas), I created a CTE to find `DISTINCT` orders and their customers.

In the main query:
- I joined the result with runner_orders
- Filtered out cancelled orders
- Grouped by customers
- Used `AVG` and `ROUND` to calculate the average distance for each customer

```sql
WITH customers AS (
    SELECT DISTINCT 
        customer_id, 
        order_id
    FROM 
        customer_orders
)

SELECT 
    customer_id,
    ROUND(
        AVG(distance), 
        1
    ) AS average_distance
FROM 
    customers
JOIN 
    runner_orders
USING (order_id)
WHERE 
    cancellation IS NULL
GROUP BY 
    customer_id
ORDER BY 
    average_distance;
```
**Output:**

| customer_id | average_distance |
| ----------- | ---------------- |
| 104         | 10               |
| 102         | 18.4             |
| 101         | 20               |
| 103         | 23.4             |
| 105         | 25               |


**Insights:**

- Customer 105 had the highest average delivery distance.
- Customer 104 had the lowest average delivery distance.
- Most customers have an average distance between 18 and 23, showing variation in delivery range.

---
**Question:** 5. What was the difference between the longest and shortest delivery times for all orders?

**Solution:**

To calculate duration from pickup to delivery:
- Use `runner_orders`
- Filter out cancelled orders
- Find the difference between longest and shortest delivery times using `MAX` and `MIN`
- Use `CONCAT` to add the word "minutes"

To calculate delivery duration from order placement to delivery:
- Create a CTE to join customer_orders and runner_orders
- Calculate the difference between `order_time` and `pickup_time` in minutes, then add duration
- In the main query, find `MIN`, `MAX`, and their difference

```sql
-- For runners:
SELECT 
    CONCAT(MAX(duration) - MIN(duration), ' minutes') AS delivery_difference
FROM 
    runner_orders
WHERE 
    duration IS NOT NULL;

-- For customers
WITH delivery AS (
    SELECT 
        TIMESTAMPDIFF(MINUTE, order_time, pickup_time) + duration AS delivery_time
    FROM 
        runner_orders 
    JOIN 
        customer_orders
    USING (order_id)
)

SELECT 
    MAX(delivery_time) AS max_delivery_time, 
    MIN(delivery_time) AS min_delivery_time, 
    MAX(delivery_time) - MIN(delivery_time) AS delivery_difference
FROM 
    delivery;
```
**Output:**

| delivery_difference |
| ------------------- |
| 30 minutes          |


| delivery_difference | max_delivery_time | min_delivery_time | delivery_difference |
| ------------------- | ----------------- | ----------------- | ------------------- |
| 30 minutes          | 69                | 25                | 44                  |


**Insights:**

Runner Duration:
- The difference between the longest and shortest runner durations is 30 minutes.
- This measures the time from pickup to delivery.
- Only uses the duration column, not including order preparation time.

Delivery Duration (Customer Orders):
- The longest delivery took 69 minutes, the shortest 25 minutes.
- The difference between the longest and shortest deliveries is 44 minutes.
- This measures the total delivery time from order placement to delivery.
- Provides a more accurate picture of delivery times than using runner duration alone.

---
**Question:** 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

**Solution:**

To calculate average speed per delivery:
- Filter orders to include only non-cancelled orders (cancellation `IS NULL`)
- Group by runner and order to calculate speed for each delivery separately
- Compute speed as distance / (duration / 60) to convert duration from minutes to hours and get km/h

```sql
SELECT 
    runner_id, 
    order_id, 
    ROUND(distance / (duration / 60), 1) AS speed
FROM 
    runner_orders
WHERE 
    duration IS NOT NULL
ORDER BY 
    runner_id, speed;
```
**Output:**

| runner_id | order_id | speed |
| --------- | -------- | ----- |
| 1         | 1        | 37.5  |
| 1         | 3        | 40.2  |
| 1         | 2        | 44.4  |
| 1         | 10       | 60    |
| 2         | 4        | 35.1  |
| 2         | 7        | 60    |
| 2         | 8        | 93.6  |
| 3         | 5        | 40    |


**Insights:**

- Runner speeds vary significantly between deliveries.
- For Runner 1, speed ranges from 37.5 to 60 km/h.
- For Runner 2, speed ranges from 35.1 to 93.6 km/h.
- For both Runner 1 and Runner 2, speed increases with subsequent orders, possibly due to a change in transportation method.
- Runner 3 has speed of 40 km/h.

---
**Question:** 7. What is the successful delivery percentage for each runner?

**Solution:**

To calculate the percentage, group by runners:
- Count the number of non-cancelled orders — take the column containing `NULL` where cancelled orders are marked (for example, duration) and divide by the total number of rows
- `ROUND` the result and use `CONCAT` to add %

```sql
SELECT 
    runner_id,
    CONCAT(ROUND(COUNT(duration) / COUNT(*) * 100, 0), '%') AS successful_delivery
FROM 
    runner_orders
GROUP BY 
    runner_id
ORDER BY 
    runner_id;
```
**Output:**

| runner_id | successful_delivery |
| --------- | ------------------- |
| 1         | 100%                |
| 2         | 75%                 |
| 3         | 50%                 |


**Insights:**

- Runner 1 completed all assigned deliveries successfully.

- Runner 2 successfully delivered 75% of orders.

- Runner 3 had the lowest success rate at 50%.

---

### C. Ingredient Optimisation

**Question:** 1. What are the standard ingredients for each pizza?

**Solution:**

CTE / Temp Table: For the answer, I first create a temporary table within the session, pizza_recipes_temp, because it will be needed in the upcoming queries.
- To convert the comma-separated numbers in a single cell, I use `JSON_ARRAY` and `REPLACE` to insert quotes between the numbers so that each number is separated.
- Then use `JSON_TABLE` to move each value from the array into a separate row.
- The resulting column is combined with the original table, producing one row per ingredient number for each pizza.

Main Query: I use this temp table in the main query.
- Join `pizza_recipes_temp` `with pizza_toppings`.
- Group by pizza.
- Retrieve the pizza name via a correlated subquery (because the pizza_names table is very small).
- Use `GROUP_CONCAT` to gather the ingredient names for each pizza into a single string.

```sql
DROP TABLE IF EXISTS pizza_recipes_temp;

CREATE TEMPORARY TABLE pizza_recipes_temp AS
SELECT 
    p.pizza_id, 
    p.toppings, 
    top.num_toppings
FROM 
    pizza_recipes p
JOIN 
    JSON_TABLE(
        REPLACE(JSON_ARRAY(p.toppings), ',', '", "'),
        '$[*]' COLUMNS (num_toppings VARCHAR(50) PATH '$')
    ) top;



SELECT 
    t.pizza_id, 
    (SELECT pizza_name 
     FROM pizza_names n 
     WHERE n.pizza_id = t.pizza_id) AS pizza_name,
    GROUP_CONCAT(p.topping_name ORDER BY p.topping_id) AS ingredients
FROM 
    pizza_recipes_temp t
JOIN 
    pizza_toppings p
ON 
    p.topping_id = t.num_toppings
GROUP BY 
    pizza_id
ORDER BY 
    pizza_id;
```
**Output:**

| pizza_id | pizza_name | ingredients                                                           |
| -------- | ---------- | --------------------------------------------------------------------- |
| 1        | Meatlovers | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 2        | Vegetarian | Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce            |


**Insights:**

Each pizza has a clearly defined set of standard ingredients. Meatlovers includes a variety of meats and sauces, while Vegetarian contains only plant-based toppings.

---
**Question:** 2. What was the most commonly added extra?

**Solution:**

Temporary Tables
- To calculate extra ingredients and answer further questions, I created two temporary tables: one for extras and one for exclusions. The queries for them are identical, only the column name differs.
- I did not create a single table for both extras and exclusions to avoid creating too many duplicate rows when a single pizza has multiple extras or exclusions.
- I added a `ROW_NUMBER()` as pizza_number to the customer_orders table. This allows multiple new rows to be correctly linked to each pizza.
- Using `JSON_ARRAY()`, `REPLACE()`, and `JSON_TABLE()`, I transformed extras/exclusions stored in a single string into separate rows and joined them back with the main table.
- Only the columns needed for analysis were selected in these temporary tables.

Main Query
- To answer the question, I used the temporary table with extras.
- Using a correlated subquery, I retrieved the topping name for each extra.
- I grouped by topping and counted how many times each topping was used.
- The results were ordered in descending order of usage, and `LIMIT 1` was applied to select the most commonly added extra.

```sql

-- Create a temporary table for exclusions
DROP TABLE IF EXISTS customer_orders_excl;
CREATE TEMPORARY TABLE customer_orders_excl AS
SELECT p.pizza_number,
       p.order_id,
       p.customer_id,
       p.pizza_id,
       excl.exclusions_num
FROM (SELECT *,
             ROW_NUMBER() OVER() AS pizza_number
      FROM customer_orders) p
JOIN JSON_TABLE(REPLACE(JSON_ARRAY(p.exclusions), ',', '","'),
                '$[*]' COLUMNS (exclusions_num VARCHAR(50) PATH '$')) excl;

-- Create a temporary table for extras
DROP TABLE IF EXISTS customer_orders_ext;
CREATE TEMPORARY TABLE customer_orders_ext AS
SELECT p.pizza_number,
       p.order_id,
       p.customer_id,
       p.pizza_id,
       ext.extras_num
FROM (SELECT *,
             ROW_NUMBER() OVER() AS pizza_number
      FROM customer_orders) p
JOIN JSON_TABLE(REPLACE(JSON_ARRAY(p.extras), ',', '","'),
                '$[*]' COLUMNS (extras_num VARCHAR(50) PATH '$')) ext;

-- Main query: find the most commonly added extra
SELECT extras_num,
       (SELECT topping_name
        FROM pizza_toppings t 
        WHERE t.topping_id = p.extras_num) AS topping_name,
       COUNT(extras_num) AS used_number
FROM customer_orders_ext p
GROUP BY extras_num, topping_name
ORDER BY used_number DESC
LIMIT 1;
```
**Output:**

| extras_num | topping_name | used_number |
| ---------- | ------------ | ----------- |
| 1          | Bacon        | 4           |


**Insights:**

Bacon was the most commonly added extra, used 4 times across all orders.

---
**Question:** 3. What was the most common exclusion?

**Solution:**

The solution is fully analogous to the previous question, but this time the temporary table with exclusions is used.

```sql
SELECT exclusions_num,
       (SELECT topping_name 
        FROM pizza_toppings t 
        WHERE t.topping_id = p.exclusions_num) AS topping_name,
       COUNT(exclusions_num) AS used_number
FROM customer_orders_excl p
GROUP BY exclusions_num, topping_name
ORDER BY used_number DESC
LIMIT 1;

```
**Output:**

| exclusions_num | topping_name | used_number |
| -------------- | ------------ | ----------- |
| 4              | Cheese       | 4           |


**Insights:**

The most commonly excluded ingredient was Cheese, excluded 4 times across all orders.

---
**Question:** 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

**Solution:**

To answer the question, three CTEs were created as templates: each contains the pizza number and either the pizza name or a comma-separated list of exclusions/extras if present, and then they were joined together with connecting words.

- First CTE: Selects the pizza number using the window function `ROW_NUMBER()` and the pizza name through a correlated subquery, since the pizza names table is small.

- Second CTE: From the temporary table with exclusions, groups by pizza number and uses `GROUP_CONCAT` along with a correlated subquery on topping_names (also small) to create a list of exclusions for each pizza.

- Third CTE: Does the same as the second, but for extras.

- Main query: Joins all three CTEs by pizza number, selects the necessary columns, and uses `CASE WHEN` to concatenate the pizza name with its modifications using connecting words depending on the presence or absence of extras/exclusions.

```sql
WITH customer_orders_number AS
(
    SELECT *, 
           ROW_NUMBER() OVER() as pizza_number,
           (SELECT pizza_name FROM pizza_names n WHERE n.pizza_id = p.pizza_id) as pizza_name
    FROM customer_orders p
),
customer_exclusions AS
(
    SELECT pizza_number, 
           GROUP_CONCAT((SELECT topping_name FROM pizza_toppings t
                         WHERE t.topping_id = ex.exclusions_num)
                        SEPARATOR ', ') as exlusions_g
    FROM customer_orders_excl ex
    GROUP BY pizza_number
),
customer_extras AS
(
    SELECT pizza_number, 
           GROUP_CONCAT((SELECT topping_name FROM pizza_toppings t
                         WHERE t.topping_id = ext.extras_num)
                        SEPARATOR ', ') as extras_g
    FROM customer_orders_ext ext
    GROUP BY pizza_number
)
SELECT order_id,
       customer_id,
       pizza_id,
       exclusions,
       extras,
       order_time, 
       CASE 
           WHEN exlusions_g IS NOT NULL AND extras_g IS NOT NULL
           THEN CONCAT(pizza_name,
                       ' - Exclude ', 
                       ex.exlusions_g, 
                       ' - Extra ',
                       ext.extras_g)
           WHEN exlusions_g IS NOT NULL AND extras_g IS NULL
           THEN CONCAT(pizza_name,
                       ' - Exclude ', 
                       ex.exlusions_g)
           WHEN exlusions_g IS NULL AND extras_g IS NOT NULL
           THEN CONCAT(pizza_name,
                       ' - Extra ',
                       ext.extras_g)
           ELSE pizza_name
       END AS order_item
FROM customer_orders_number p
JOIN customer_exclusions ex USING(pizza_number)
JOIN customer_extras ext USING(pizza_number);
```
**Output:**

| order_id | customer_id | pizza_id | exclusions | extras | order_time           | order_item                                    |
|----------|-------------|----------|------------|--------|--------------------|-----------------------------------------------|
| 1        | 101         | 1        | null       | null   | 2020-01-01 18:05:02 | Meatlovers                                    |
| 2        | 101         | 1        | null       | null   | 2020-01-01 19:00:52 | Meatlovers                                    |
| 3        | 102         | 1        | null       | null   | 2020-01-02 23:51:23 | Meatlovers                                    |
| 3        | 102         | 2        | null       | null   | 2020-01-02 23:51:23 | Vegetarian                                   |
| 4        | 103         | 1        | 4          | null   | 2020-01-04 13:23:46 | Meatlovers - Exclude Cheese                  |
| 4        | 103         | 1        | 4          | null   | 2020-01-04 13:23:46 | Meatlovers - Exclude Cheese                  |
| 4        | 103         | 2        | 4          | null   | 2020-01-04 13:23:46 | Vegetarian - Exclude Cheese                  |
| 5        | 104         | 1        | null       | 1      | 2020-01-08 21:00:29 | Meatlovers - Extra Bacon                     |
| 6        | 101         | 2        | null       | null   | 2020-01-08 21:03:13 | Vegetarian                                   |
| 7        | 105         | 2        | null       | 1      | 2020-01-08 21:20:29 | Vegetarian - Extra Bacon                     |
| 8        | 102         | 1        | null       | null   | 2020-01-09 23:54:33 | Meatlovers                                    |
| 9        | 103         | 1        | 4          | 1,5    | 2020-01-10 11:22:59 | Meatlovers - Exclude Cheese - Extra Bacon, Chicken |
| 10       | 104         | 1        | null       | null   | 2020-01-11 18:34:49 | Meatlovers                                    |
| 10       | 104         | 1        | 2,6        | 1,4    | 2020-01-11 18:34:49 | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |


**Insights:**

The query successfully combines pizza names with any exclusions and extras for each pizza, producing a clear, human-readable description of every order item.

---
**Question:** 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami" 

**Solution:**

Overview / Setup

- Because MySQL does not allow using the same table multiple times within temporary tables or CTEs, two temporary tables were created:
    - First temporary table: subtracts exclusions from the pizza ingredients.
    - Second temporary table: adds extras to the results from the first temporary table.
- In a CTE, added the x prefix where needed
- In the main query generated a full ingredient list for each pizza.

Temporary Tables
- First temporary table:
    - Took `customer_orders_ext` with separate rows per pizza.
    - Joined with `pizza_recipes_temp` containing full ingredient lists for each pizza to create rows with each ingredient per pizza.
    - Checked each ingredient against the exclusions for that pizza using a correlated subquery.
    - Used `CASE WHEN` to set excluded ingredients to `NULL`.
    - Selected only ingredients that were not `NULL`.

- Second temporary table:
    - Added all extras to the results from the first temporary table.
    - Used `UNION ALL` to keep duplicates and renamed extra numbers to match ingredient numbering format of the first table.

- CTE 
    - Added the x prefix for ingredients appearing more than once using `CASE WHEN` and `CONCAT`.
    - Assigned a row number per ingredient per pizza in alphabetical order using `ROW_NUMBER()`.

- Main Query
    - Grouped by pizza
    -  Used `GROUP_CONCAT` with a correlated subquery to produce a complete, comma-separated, alphabetically ordered list of all ingredients for each pizza.

```sql

-- Create a temporary table accounting for excluded toppings
DROP TABLE IF EXISTS pizza_ingr_excluded;
CREATE TEMPORARY TABLE pizza_ingr_excluded AS

WITH excluded_pizza AS
(
    SELECT c.pizza_number, order_id, customer_id, pizza_id, 
           CASE WHEN num_toppings NOT IN (SELECT exclusions_num 
                                          FROM customer_orders_excl ex
                                          WHERE c.pizza_number = ex.pizza_number
                                          AND exclusions_num IS NOT NULL)
                THEN num_toppings 
                ELSE NULL END AS num_toppings
    FROM (SELECT DISTINCT pizza_number, order_id, customer_id, pizza_id
          FROM customer_orders_ext) c
    JOIN pizza_recipes_temp p
    USING(pizza_id)
)
 
SELECT pizza_number,
       order_id,
       customer_id,
       pizza_id,
       num_toppings
FROM excluded_pizza
WHERE num_toppings IS NOT NULL;


-- Create a temporary table combining all ingredients including extras
DROP TABLE IF EXISTS all_ingr;
CREATE TEMPORARY TABLE all_ingr AS

SELECT *
FROM pizza_ingr_excluded

UNION ALL

SELECT pizza_number,
       order_id,
       customer_id,
       pizza_id,
       extras_num AS num_toppings
FROM customer_orders_ext 
WHERE extras_num IS NOT NULL
    
ORDER BY pizza_number, num_toppings;


-- CTE to add 'x' prefix for multiple toppings and prepare for alphabetical ordering
WITH all_ingr_str AS
(
    SELECT pizza_number,
           order_id,
           customer_id,
           pizza_id,
           num_toppings,
           CASE WHEN COUNT(num_toppings) = 1 THEN topping_name
                ELSE CONCAT (COUNT(num_toppings), 'x', topping_name) END as topping_name,
           ROW_NUMBER() OVER( ORDER BY topping_name) as top_order
    FROM all_ingr a
    JOIN pizza_toppings p
    ON a.num_toppings = p.topping_id
    GROUP BY pizza_number, order_id, customer_id, pizza_id, num_toppings, topping_name
)
 
-- Main query: generate alphabetically ordered, comma-separated ingredient list per pizza order
SELECT 
    order_id,
    customer_id,
    pizza_id,
    CONCAT ((SELECT pizza_name FROM pizza_names p 
             WHERE p.pizza_id = a.pizza_id), ': ',
            GROUP_CONCAT(topping_name 
                         ORDER BY top_order SEPARATOR ', ')) as ingredients
FROM all_ingr_str a
GROUP BY pizza_number, order_id, customer_id, pizza_id
ORDER BY order_id, customer_id, pizza_id;

```
**Output:**

| order_id | customer_id | pizza_id | ingredients                                                                         |
| -------- | ----------- | -------- | ----------------------------------------------------------------------------------- |
| 1        | 101         | 1        | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 2        | 101         | 1        | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 3        | 102         | 1        | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 3        | 102         | 2        | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes              |
| 4        | 103         | 1        | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami           |
| 4        | 103         | 1        | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami           |
| 4        | 103         | 2        | Vegetarian: Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes                      |
| 5        | 104         | 1        | Meatlovers: 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 6        | 101         | 2        | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes              |
| 7        | 105         | 2        | Vegetarian: Bacon, Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes       |
| 8        | 102         | 1        | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 9        | 103         | 1        | Meatlovers: 2xBacon, BBQ Sauce, Beef, 2xChicken, Mushrooms, Pepperoni, Salami       |
| 10       | 104         | 1        | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 10       | 104         | 1        | Meatlovers: 2xBacon, Beef, 2xCheese, Chicken, Pepperoni, Salami                     |


**Insights:**

- This table shows a complete, alphabetically ordered ingredient list for each pizza order.

- Any ingredient added multiple times is prefixed with 2x to indicate duplicates.

- Exclusions are automatically removed, and extras are included, giving a full picture of what was actually prepared for each pizza.

---

**Question:** 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

**Solution:**

CTE:
-  Created a subquery with only successful orders
- Filtered runner_orders where orders were not cancelled and selected only order numbers.

Main query:
- Left joined this CTE with `all_ingr`, which contains ingredients for each pizza.
- Joined with `pizza_toppings` to get ingredient names.
- Grouped by ingredient and used `COUNT` to calculate how often each ingredient was used.
- Ordered results by frequency of usage.

```sql

-- Create CTE for successfully delivered orders (filter out cancelled orders)
WITH delivered_orders AS
(
    SELECT order_id
    FROM runner_orders o
    WHERE cancellation IS NULL
)

-- Main query: calculate total quantity of each ingredient used in delivered pizzas
SELECT 
    a.num_toppings AS topping_id,
    t.topping_name,
    COUNT(a.num_toppings) as topping_quantity
FROM delivered_orders o
LEFT JOIN all_ingr a
USING(order_id)
JOIN pizza_toppings t
    ON t.topping_id = a.num_toppings
GROUP BY a.num_toppings, t.topping_name
ORDER BY topping_quantity DESC, CAST(a.num_toppings AS SIGNED);

```
**Output:**

| topping_id | topping_name | topping_quantity |
| ---------- | ------------ | ---------------- |
| 1          | Bacon        | 12               |
| 6          | Mushrooms    | 11               |
| 4          | Cheese       | 10               |
| 3          | Beef         | 9                |
| 5          | Chicken      | 9                |
| 8          | Pepperoni    | 9                |
| 10         | Salami       | 9                |
| 2          | BBQ Sauce    | 8                |
| 7          | Onions       | 3                |
| 9          | Peppers      | 3                |
| 11         | Tomatoes     | 3                |
| 12         | Tomato Sauce | 3                |



**Insights:**

This table shows the total quantity of each ingredient used across all successfully delivered pizzas, sorted from most frequent to least frequent. Bacon, mushrooms, and cheese are the most frequent, while onions, peppers, tomatoes, and tomato sauce are the least frequent.

---

### D. Pricing and Ratings

**Question:** 1 If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?


**Solution:**

- Joined `customer_orders` with `runner_orders`.
- Filtered only non-cancelled orders.
- Used `CASE WHEN` to assign price: 12 for Meat Lovers, 10 for Vegetarian.
- Summed all prices to get total revenue.
- Used `CONCAT` to append the $ sign.

```sql

SELECT CONCAT(SUM(
           CASE 
               WHEN pizza_id = 1 THEN 12
               ELSE 10 
           END), '$') as cost
FROM runner_orders
JOIN customer_orders
USING(order_id)
WHERE cancellation IS NULL;


```
**Output:**

| cost |
| ---- |
| 138$ |

**Insights:**

Total revenue from all delivered pizzas so far, given Meat Lovers $12, Vegetarian $10, and no extra charges or delivery fees, is 138.

---

**Question:** 2. What if there was an additional $1 charge for any pizza extras?

**Solution:**

The solution is similar to the previous one, but a CTE is added to calculate how many extras there were for each pizza.

CTE:
- Used the temporary table `customer_orders_ext`.
- Grouped by pizzas 
- Counted the number of extras for each pizza.

Main query:
- Joined with `runner_orders`.
- Filtered only non-cancelled orders.
- Used `CASE WHEN` to assign prices: 12 + extras for Meat Lovers, 10 + extras for Vegetarian.
- Summed all prices to get the total revenue.
- Used `CONCAT` to append the $ sign.

```sql

WITH extra_count AS
(
    SELECT order_id, pizza_id, 
           COUNT(extras_num) as extras
    FROM customer_orders_ext
    GROUP BY pizza_number, order_id, pizza_id
)

SELECT CONCAT(
           SUM(
               CASE 
                   WHEN pizza_id = 1 THEN 12 + extras
                   ELSE 10 + extras 
               END
           ), '$'
       ) as cost
FROM runner_orders
JOIN extra_count
USING(order_id)
WHERE cancellation IS NULL;

```
**Output:**

| cost |
| ---- |
| 142$ |



**Insights:**

With an additional $1 charge per extra topping, the total revenue from non-cancelled orders increases from $138 to $142.

---

**Question:** 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.


**Solution:**

- Created the ratings table:
    - added columns for rating_id, order_id, runner_id, customer_id, rating_time (with default current timestamp), and rating_number with a check constraint between 0 and 5.
- Described the table to verify the table structure.

- Joined `customer_orders` and `runner_orders`.

- Filtered only non-cancelled orders.

- Selected `DISTINCT` `order_id`, `customer_id`, and `runner_id`.

- Used the `RAND()` function to generate a number between 0 and 1, multiplied it by 5, and applied `CEIL()` to get a rating from 0 to 5.

- Inserted these values into the new ratings table.

```sql

DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings(
  rating_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT,
  runner_id INT,
  customer_id INT,
  rating_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  rating_number INT CHECK (rating_number BETWEEN 0 AND 5)
);

DESCRIBE ratings;

INSERT INTO ratings (order_id, runner_id, customer_id, rating_number)
SELECT DISTINCT order_id, runner_id, customer_id, 
       CEIL(RAND()*5) as rating_number
FROM customer_orders
JOIN runner_orders
USING(order_id)
WHERE cancellation IS NULL
GROUP BY order_id, runner_id, customer_id
ORDER BY order_id;

SELECT * FROM ratings;

```
**Output:**

| rating_id | order_id | runner_id | customer_id | rating_time         | rating_number |
| --------- | -------- | --------- | ----------- | ------------------- | ------------- |
| 1         | 1        | 1         | 101         | 2026-01-20 06:43:44 | 2             |
| 2         | 2        | 1         | 101         | 2026-01-20 06:43:44 | 5             |
| 3         | 3        | 1         | 102         | 2026-01-20 06:43:44 | 4             |
| 4         | 4        | 2         | 103         | 2026-01-20 06:43:44 | 1             |
| 5         | 5        | 3         | 104         | 2026-01-20 06:43:44 | 1             |
| 6         | 7        | 2         | 105         | 2026-01-20 06:43:44 | 4             |
| 7         | 8        | 2         | 102         | 2026-01-20 06:43:44 | 1             |
| 8         | 10       | 1         | 104         | 2026-01-20 06:43:44 | 4             |


---

**Question:** 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas


**Solution:**

Created two CTEs for preliminary data processing to simplify the main query.
- The first CTE extracts information from `customer_orders` and calculates the total number of pizzas per order using `GROUP BY` and `COUNT`.
- The second CTE selects only non-cancelled orders from `runner_orders`.
- Main query:
    - Joined the two CTEs with the ratings table.
    - Selected the necessary columns.
    - Calculated the time between order and pickup using `TIMESTAMPDIFF`.
    - Calculated the average speed in km/h using a formula and `ROUND`.

```sql

WITH customer_orders_cte AS
(
    SELECT order_id, customer_id, order_time,
           COUNT(*) as total_number_of_pizzas
    FROM customer_orders
    GROUP BY order_id, customer_id, order_time
),

runner_orders_cte AS
(
    SELECT order_id, runner_id, pickup_time, distance, duration
    FROM runner_orders
    WHERE cancellation IS NULL
)

SELECT c.customer_id, c.order_id, r.runner_id, 
       rat.rating_number, c.order_time, r.pickup_time, 
       TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time) as time_between_order_pickup,
       r.duration, 
       ROUND(r.distance/(r.duration/60),1) as average_speed,
       c.total_number_of_pizzas
FROM runner_orders_cte r
JOIN customer_orders_cte c
USING(order_id)
JOIN ratings rat
USING(order_id);

```
**Output:**

| customer_id | order_id | runner_id | rating_number | order_time          | pickup_time         | time_between_order_pickup | duration | average_speed | total_number_of_pizzas |
| ----------- | -------- | --------- | ------------- | ------------------- | ------------------- | ------------------------- | -------- | ------------- | ---------------------- |
| 101         | 1        | 1         | 1             | 2020-01-01 18:05:02 | 2020-01-01 18:15:34 | 10                        | 32       | 37.5          | 1                      |
| 101         | 2        | 1         | 3             | 2020-01-01 19:00:52 | 2020-01-01 19:10:54 | 10                        | 27       | 44.4          | 1                      |
| 102         | 3        | 1         | 2             | 2020-01-02 23:51:23 | 2020-01-03 00:12:37 | 21                        | 20       | 40.2          | 2                      |
| 103         | 4        | 2         | 3             | 2020-01-04 13:23:46 | 2020-01-04 13:53:03 | 29                        | 40       | 35.1          | 3                      |
| 104         | 5        | 3         | 3             | 2020-01-08 21:00:29 | 2020-01-08 21:10:57 | 10                        | 15       | 40            | 1                      |
| 105         | 7        | 2         | 4             | 2020-01-08 21:20:29 | 2020-01-08 21:30:45 | 10                        | 25       | 60            | 1                      |
| 102         | 8        | 2         | 4             | 2020-01-09 23:54:33 | 2020-01-10 00:15:02 | 20                        | 15       | 93.6          | 1                      |
| 104         | 10       | 1         | 4             | 2020-01-11 18:34:49 | 2020-01-11 18:50:20 | 15                        | 10       | 60            | 2                      |


---

**Question:** 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?


**Solution:**

CTE
- Calculated the total cost of each order.
- Assigned a fixed price of $12 for Meat Lovers and $10 for Vegetarian pizzas using `CASE WHEN`.
- Aggregated pizza prices per order using `SUM`.

Main query
- Joined the CTE with `runner_orders`.
- Filtered only non-cancelled orders.
- Calculated runner salary as distance * 0.3 for each delivery.
- Summed total pizza revenue and total runner salary.
- Used `ROUND` to round runner salary.
- Calculated final revenue by subtracting total runner salary from total pizza cost.

```sql

WITH pizza_price AS (
    SELECT 
        order_id,
        SUM(
            CASE 
                WHEN pizza_id = 1 THEN 12
                ELSE 10 
            END
        ) AS pizzas_cost
    FROM customer_orders
    GROUP BY order_id
)

SELECT 
    SUM(pizzas_cost) AS pizzas_cost,
    ROUND(SUM(distance * 0.3), 1) AS runner_salary,
    ROUND(SUM(pizzas_cost - distance * 0.3), 1) AS revenue
FROM pizza_price
JOIN runner_orders
USING (order_id)
WHERE cancellation IS NULL;


```
**Output:**

| pizzas_cost | runner_salary | revenue |
| ----------: | ------------: | ------: |
|         138 |          43.6 |    94.4 |


**Insights:**

After paying runners $0.30 per kilometre for all successful deliveries, Pizza Runner is left with $94.4 in revenue from $138 total pizza sales.

---

### E. Bonus Questions

**Question:** If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

**Solution:**

I inserted new data for the Supreme pizza into both `pizza_names` and `pizza_recipes`.

- Insert into `pizza_names`
    - Added a new pizza entry with a new id 3 and the name Supreme pizza.
- Insert into `pizza_recipes`
    - Since the Supreme pizza includes all ingredients from `pizza_toppings` except bacon, BBQ sauce, and chicken, I selected all id values from `pizza_toppings` excluding these three.
    - Used `GROUP_CONCAT` to combine the selected topping IDs into a single comma-separated list.
    - Inserted this list as the toppings value for the Supreme pizza in pizza_recipes.

```sql

INSERT INTO pizza_names VALUES
(3, 'Supreme pizza');

INSERT INTO pizza_recipes VALUES
(
    3,
    (
        SELECT GROUP_CONCAT(topping_id ORDER BY topping_id)
        FROM pizza_toppings
        WHERE topping_id NOT IN (1, 2, 5)
    )
);

SELECT *
FROM pizza_names;

SELECT *
FROM pizza_recipes;

```
**Output:**

| pizza_id | pizza_name    |
| -------: | ------------- |
|        1 | Meatlovers    |
|        2 | Vegetarian    |
|        3 | Supreme pizza |

| pizza_id | toppings             |
| -------: | -------------------- |
|        1 | 1,2,3,4,5,6,8,10     |
|        2 | 4,6,7,9,11,12        |
|        3 | 3,4,6,7,8,9,10,11,12 |



**Insights:**

The new Supreme pizza is added without changing the existing data design — only new rows are inserted into `pizza_names` and `pizza_recipes`. This confirms the schema is flexible and easily extensible for adding new pizzas.

---

## 🔹 Overall Summary

This case included both straightforward and more complex tasks. Questions **a**, **b**, **d**, and **e** were relatively simple, using standard SQL techniques, while question **C** was longer and more complex, requiring the creation of **temporary tables** and careful handling of multiple transformations.  

### Straightforward methods reinforced:
- Extensive use of **aggregations** (`SUM`, `COUNT`, `AVG`, `GROUP_CONCAT`) to summarize customer behavior and ingredients usage.  
- Application of **window functions** (`RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`) to analyze sequences, orderings, and ranking of purchases.  
- Implementation of **conditional logic** via `CASE WHEN` for prices, extras, exclusions, and calculated columns.  
- Use of **CTEs / temporary tables** to structure queries clearly and handle complex transformations.  

### New concept learned:
- **Splitting comma-separated values into rows** using `JSON_ARRAY()` and `JSON_TABLE()`, which allowed transforming values like `1,2,3,4` into multiple rows, with one value per row.  
- This technique was slightly more challenging and applied specifically to question **C** for handling pizza ingredients, extras, and exclusions.  

**Overall:** This case strengthened my ability to combine standard SQL methods with newer techniques to solve complex data transformation problems, preparing me for real-world junior data analyst tasks.
