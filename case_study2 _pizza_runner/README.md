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
![Entity Relationship Diagram](https://github.com/Sveta2732/-8_week_SQL_challenge/blob/59b5928af6c492766c7e8c331263b8cdc798b580/case_study1_dannys_diner/ERD.png?raw=true)
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



**Insights:**



---
**Question:** 

**Solution:**



```sql

```
**Output:**



**Insights:**



---
**Question:** 

**Solution:**



```sql

```
**Output:**



**Insights:**



---
**Question:** 

**Solution:**



```sql

```
**Output:**



**Insights:**



---