# 🥢 Case 01 — Danny’s Diner

## 📖 Business Context
This case study focuses on helping **Danny’s Diner**, a small restaurant that sells sushi, curry, and ramen, better understand its customers through SQL analysis. Danny wants to use data from his sales, menu, and members tables to answer key business questions about customer behavior, spending, and loyalty in order to make smarter decisions about marketing and customer engagement.
Danny recently opened **Danny’s Diner** at the beginning of 2021 and captures basic data on customer purchases and membership. He needs insights into patterns such as:

- How much each customer spends  
- How often they visit  
- Which items are favourites  
- Loyalty program activity and timing  

These insights can help him decide whether to expand his **loyalty program** and improve customer experience. 

![Case Study Design](https://8weeksqlchallenge.com/images/case-study-designs/1.png)

---
## 🛠 SQL Concepts & Functions Used

This case demonstrates the following SQL skills and techniques applied to analyze Danny’s Diner data:

- **Joins** (`JOIN ... USING`, `LEFT JOIN`, `RIGHT JOIN`) to combine `sales`, `menu`, and `members` tables for enriched customer-level insights.  
- **Window functions** (`RANK()`, `DENSE_RANK()`,  `ROW_NUMBER()` `OVER(PARTITION BY ... ORDER BY ...)`) to identify first purchases, most popular items, and ranking of orders for each customer.  
- **CTEs** (`WITH`) to structure intermediate queries, e.g., calculating first/last purchases or points earned by members.  
- **Aggregation & GROUP BY** (`COUNT`, `SUM`, `AVG`, `GROUP_CONCAT`, `DISTINCT`) to compute total spending, total items, frequency of visits, and popular menu items.  
- **CASE WHEN** to implement conditional logic, e.g., differentiating points multipliers, checking membership status, and handling NULL values.  
- **Date functions** (`DATE_ADD`) to calculate points earned within specific time windows (e.g., first week after joining).  
- **COALESCE** to handle missing values and provide default labels for non-members or absent data.  
- **ORDER BY / LIMIT** to control output order and display top items or sequences.  
- **String functions** (`GROUP_CONCAT`) to combine multiple items into a single list per customer.  

These techniques were applied to translate business questions into SQL queries and extract actionable insights, such as customer spending habits, menu item popularity, loyalty program engagement, and reward point calculations.

---

## 📊 Datasets
The case uses three key datasets from the dannys_diner database:  

- **`sales`** — captures all customer purchases with customer_id, order_date, and product_id

| customer_id | order_date  | product_id |
|------------|------------|------------|
| A          | 2021-01-01 | 1          |
| A          | 2021-01-01 | 2          |
| A          | 2021-01-07 | 2          |
| A          | 2021-01-10 | 3          |
| A          | 2021-01-11 | 3          |
| A          | 2021-01-11 | 3          |
| B          | 2021-01-01 | 2          |
| B          | 2021-01-02 | 2          |
| B          | 2021-01-04 | 1          |
| B          | 2021-01-11 | 1          |
| B          | 2021-01-16 | 3          |
| B          | 2021-02-01 | 3          |
| C          | 2021-01-01 | 3          |
| C          | 2021-01-01 | 3          |
| C          | 2021-01-07 | 3          |


- **`menu`** — maps product_id to product_name and price

| product_id | product_name | price |
|-----------|--------------|-------|
| 1         | sushi        | 10    |
| 2         | curry        | 15    |
| 3         | ramen        | 12    |


- **`members`** — shows when a customer joined the loyalty program 

| customer_id | join_date  |
|------------|------------|
| A          | 2021-01-07 |
| B          | 2021-01-09 |



###  Entity Relationship Diagram (ERD)
![Entity Relationship Diagram](https://8weeksqlchallenge.com/images/case-study-3-erd.png)
---


## 🛠 Tools

- **MySQL**

---

## ❓ Questions & Solutions
### Case Study Questions
**Question:** 1. What is the total amount each customer spent at the restaurant?

**Solution:**

To calculate the total amount spent by each customer, I joined the sales table with the menu table to retrieve product prices. Then I:
- Grouped the data by customer_id.
- Used the `SUM()` aggregate function to compute total spending per customer.
- `CONCAT()` was used to append the dollar sign to the total amount.
- Sorted the results by customer_id for clear presentation and easy analysis.
```sql
SELECT s.customer_id, 
       CONCAT('$', SUM(m.price)) AS total_amount
FROM sales s 
JOIN menu m
USING (product_id)
GROUP BY s.customer_id
ORDER BY s.customer_id;
```
**Output:**
| customer_id | total_amount |
| ----------- | ------------ |
| A           | $76          |
| B           | $74          |
| C           | $36          |


**Insights:**

- Customer A spent the most at the restaurant, followed closely by B.

- Customer C spent significantly less, indicating either fewer visits or cheaper items purchased.

This information can help identify high-value customers and tailor promotions or loyalty rewards.

---

**Question:** 2. How many days has each customer visited the restaurant?

**Solution:**
To get the answer, I simply group the sales table by customers.
- The number of distinct order_date values is counted using `COUNT(DISTINCT)`.
- `CONCAT()` is used to append the text “days” to make the output more readable.

```sql
SELECT customer_id, 
       CONCAT(COUNT(DISTINCT order_date), ' days') as number_of_days
FROM sales
GROUP BY customer_id
ORDER BY customer_id;
```
**Output:**
| customer_id | number_of_days |
| ----------- | -------------- |
| A           | 4 days         |
| B           | 6 days         |
| C           | 2 days         |


**Insights:**

- Customer B visited the restaurant the most frequently, with 6 unique days of visits.

- Customer A visited 4 different days, while Customer C was the least frequent, visiting only 2 days.

- Tracking the number of distinct visit days helps understand customer engagement and loyalty patterns.

---

**Question:** 3. What was the first item from the menu purchased by each customer?

**Solution:**

I used two approaches to find the first item(s) purchased by each customer:
- Using a CTE with a window function:
    - Created a `CTE window_sale` by joining sales with menu to get product names instead of just IDs.
    - Applied the `RANK()` window function partitioned by customer_id and ordered by order_date. This assigns a rank to each row, ensuring that multiple items purchased on the same day receive the same rank.
    - Filtered the CTE to keep only rows with rank = 1 (the first day of purchase), grouped by customer, and used `GROUP_CONCAT` to combine items purchased on the same day.

- Using a correlated subquery:
    - For each customer in the main query, selected matching rows from sales and joined with menu to get product names.
    - Grouped rows by order_date and used `GROUP_CONCAT` to combine items purchased on the same day.
    - Applied `LIMIT` 1 to return only the first purchase day’s items for each customer.

Both approaches return the same results, but the first approach using a window function is more scalable and readable for larger datasets.

```sql
WITH window_sale AS (
    SELECT s.customer_id, 
           m.product_name, 
           RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS product_rank
    FROM sales s 
    JOIN menu m
    USING (product_id)
)
SELECT customer_id, 
       GROUP_CONCAT(DISTINCT product_name) AS first_item
FROM window_sale 
WHERE product_rank = 1
GROUP BY customer_id;


-- Alternative solution for question 3
SELECT s.customer_id, 
       (SELECT GROUP_CONCAT(DISTINCT m.product_name SEPARATOR ', ') 
        FROM sales s2 
        JOIN menu m USING (product_id)
        WHERE s.customer_id = s2.customer_id
        GROUP BY order_date
        ORDER BY s2.order_date
        LIMIT 1) AS first_item
FROM sales s
GROUP BY customer_id
ORDER BY customer_id;
```
**Output:**
| customer_id | first_item   |
| ----------- | ------------ |
| A           | curry, sushi |
| B           | curry        |
| C           | ramen        |


**Insights:**

The first items purchased by each customer vary, showing individual preferences. Customer A tried both curry and sushi on their first visit, while B and C each started with a single item, indicating a mix of exploration and focus on favorites.

---

**Question:** 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

**Solution:**

For this analysis, a correlated subquery was used to get the product_name for each product_id. Data was grouped by product, counted, sorted in descending order, and LIMIT 1 selected the most popular item.

Using a correlated subquery is justified for a small dataset, as it may slow down query performance on larger datasets.

```sql
SELECT (SELECT m.product_name
        FROM menu m
        WHERE s.product_id =m.product_id) AS product_name,
        COUNT(*) AS times_was_purchased
FROM sales s
GROUP BY product_id
ORDER BY times_was_purchased DESC
LIMIT 1;
```
**Output:**
| product_name | times_was_purchased |
|--------------|-------------------|
| ramen        | 8                 |


**Insights:**
Ramen was the most purchased menu item, with a total of 8 orders across all customers.

---

**Question:** 5. Which item was the most popular for each customer?

**Solution:**

- The solution uses a CTE (sales_group) to first aggregate sales by customer and product, counting how many times each product was purchased.
 - A window function (`RANK()`) is applied within each customer partition, ordered by product count descending, to assign a rank to each product.
- In the main query, we filter for rank = 1 to select the most popular product(s) per customer.
- `GROUP_CONCAT` is used to combine multiple equally popular products into a single string for each custome

```sql
WITH sales_group AS (
    SELECT 
        customer_id, 
        product_id, 
        COUNT(*) AS product_count,
        RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS rank_number
    FROM sales
    GROUP BY customer_id, product_id
)
                                        
SELECT 
    a.customer_id, 
    GROUP_CONCAT(m.product_name SEPARATOR ', ') AS product_name, 
    a.product_count
FROM sales_group a 
JOIN menu m
USING (product_id)
WHERE rank_number = 1
GROUP BY a.customer_id, a.product_count
ORDER BY a.customer_id;
```
**Output:**
| customer_id | product_name       | product_count |
|-------------|------------------|----------------|
| A           | ramen            | 3              |
| B           | sushi, curry, ramen | 2           |
| C           | ramen            | 3              |


**Insights:**

Ramen is consistently among the most popular items for all customers, showing it as a customer favorite. Some customers, like B, have multiple items tied in popularity, indicating varied preferences alongside ramen.

---

**Question:** 6. Which item was purchased first by the customer after they became a member?

**Solution:**

- The solution uses a CTE (rank_sales) where sales is joined with menu to get product names.
- A correlated subquery filters only orders where the order_date is on or after the customer's membership join date.
- A window function (`RANK()`) assigns a rank to each product per customer based on order date.
- In the main query, a `RIGHT JOIN` combines the CTE with all customers to include those who are not yet members.
- Rows with rank = 1 (first purchase after joining) or NULL rank (non-members) are selected.
- `COALESCE` is used to label non-member customers as "not member".

This approach ensures that both members and non-members are included while accurately identifying the first post-membership purchase.

```sql
WITH rank_sales AS 
(
    SELECT s.customer_id, m.product_name, 
           RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank_number
    FROM sales s 
    JOIN menu m
    USING (product_id)
    WHERE order_date >= 
          (SELECT join_date 
           FROM members me
           WHERE s.customer_id = me.customer_id)
)

SELECT s.customer_id, COALESCE(r.product_name, 'not member') as first_product
FROM rank_sales r 
RIGHT JOIN 
    (SELECT customer_id 
     FROM sales
     GROUP BY customer_id) s
USING (customer_id)
WHERE rank_number < 2 OR rank_number IS NULL
ORDER BY customer_id;

```
**Output:**
| customer_id | first_product |
| ----------- | ------------- |
| A           | curry         |
| B           | sushi         |
| C           | not member    |


**Insights:**

The query identifies the first item each customer purchased after joining the membership program. Customers who had not yet joined are labeled as "not member." This helps track initial engagement with the menu post-membership.

---

**Question:** 7. Which item was purchased just before the customer became a member?

**Solution:**

The solution is similar to the previous one, but for clarity and readability, each step was separated into its own CTE:
- Step 1: Combine the sales, menu, and members tables and filter orders that occurred before the customer’s join date. Assign a rank to each product per customer using a window function (`RANK()`) ordered by order_date descending.
- Step 2: Filter the ranked results to keep only rank = 1, i.e., the most recent items purchased before joining. Group by customer_id and use `GROUP_CONCAT` to merge multiple products with the same rank into a single row.
- Step 3: Retrieve all customer_ids from sales, including non-members.

In the final query, the second and third CTEs are combined using a RIGHT JOIN to ensure all customers are included. `COALESCE` is used to mark customers without membership as "not member".

This approach improves readability and makes it easier to debug or extend the analysis in the future.

```sql
WITH window_sale AS (
    SELECT 
        s.customer_id, 
        m.product_name, 
        RANK() OVER(
            PARTITION BY customer_id 
            ORDER BY order_date DESC
        ) AS rn
    FROM sales s
    JOIN menu m USING (product_id)
    JOIN members me USING (customer_id)
    WHERE order_date < join_date
),

window_sale_filtered AS (
    SELECT 
        customer_id, 
        GROUP_CONCAT(DISTINCT product_name SEPARATOR ', ') AS last_product
    FROM window_sale
    WHERE rn = 1
    GROUP BY customer_id
),

customers AS (
    SELECT customer_id
    FROM sales
    GROUP BY customer_id
)

SELECT 
    s.customer_id, 
    COALESCE(w.last_product, 'not member') AS last_product
FROM window_sale_filtered w
RIGHT JOIN customers s USING (customer_id)
ORDER BY s.customer_id;
```
**Output:**
| customer_id | last_product |
| ----------- | ------------ |
| A           | curry, sushi |
| B           | sushi        |
| C           | not member   |


**Insights:**

For customers who became members, this shows the last items they purchased before joining. Customer C had no membership yet, so "not member" is indicated. Both Customer A and Customer B purchased sushi before joining the membership program, which may suggest that they decided to become members because they particularly enjoy sushi. This insight can guide targeted promotions for new or prospective members.

---

**Question:** 8. What is the total items and amount spent for each member before they became a member?

**Solution:**

The code uses two CTEs:
- The first CTE (agg_sales) joins all three tables, filters for products purchased before the customer’s join date, and calculates total items and total spending per customer.
- The second CTE (customers) lists all customer IDs, including those who are not yet members.

In the main query, the two CTEs are joined, and `COALESCE` is used to label non-members as 'not member'.

```sql
WITH agg_sales AS (
    SELECT customer_id,
           COUNT(product_id) AS total_items,
           SUM(price) AS total_spending
    FROM sales s
    JOIN menu m
    USING(product_id)
    JOIN members me
    USING(customer_id)
    WHERE s.order_date < me.join_date
    GROUP BY customer_id
),

customers AS (
    SELECT customer_id
    FROM sales
    GROUP BY customer_id
)

SELECT c.customer_id, 
       COALESCE(s.total_items, 'not member') AS total_items, 
       COALESCE(s.total_spending, 'not member') AS total_spending
FROM agg_sales s
RIGHT JOIN customers c
USING(customer_id);
```
**Output:**
| customer_id | total_items | total_spending |
| ----------- | ----------- | -------------- |
| A           | 2           | 25             |
| B           | 3           | 40             |
| C           | not member  | not member     |


**Insights:**

This shows the total items purchased and total amount spent by each customer before they became a member. Customer C had not yet joined, so "not member" is indicated. Customers A and B purchased items more than once before joining, indicating repeated engagement with the restaurant. This insight can help identify loyal visitors and guide strategies to convert frequent visitors into members.

---

**Question:** 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

**Solution:**

The solution is straightforward and follows a clear logical flow:

- Join the sales and menu tables to access product prices.
- Use a `CASE WHEN` statement to calculate points for each item
(2× points for sushi, standard points for all other items).
- Group the results by customer_id and sum the points to get total points per customer.

If points are earned only by members after joining:
- Extend the solution by adding a `RIGHT JOIN` with the members table to include only customers who became members.
- Apply a filter to keep orders placed on or after the join_date, ensuring that only post-membership purchases earn points.


```sql
-- Points earned by ALL customers (no membership restrictions)
SELECT s.customer_id,
       SUM(
           CASE 
               WHEN m.product_name = 'sushi'
                   THEN m.price * 20
               ELSE m.price * 10
           END
       ) AS points
FROM sales s
JOIN menu m
USING (product_id)
GROUP BY s.customer_id
ORDER BY customer_id;

-- Points earned by MEMBERS ONLY (after joining the membership program)
SELECT s.customer_id,
       SUM(
           CASE 
               WHEN m.product_name = 'sushi'
                   THEN m.price * 20
               ELSE m.price * 10
           END
       ) AS points
FROM sales s
JOIN menu m
USING (product_id)
RIGHT JOIN members me
USING (customer_id)
WHERE s.order_date >= me.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;
```
**Output:**

Points earned by ALL customers (no membership restrictions):
| customer_id | points |
| ----------- | ------ |
| A           | 860    |
| B           | 940    |
| C           | 360    |

Points earned by MEMBERS ONLY (after joining the membership program):
| customer_id | points |
| ----------- | ------ |
| A           | 510    |
| B           | 440    |


**Insights:**

- If points are earned by all customers:
    - Customer B earned the most points overall. This aligns with earlier findings that B spent more and ordered more items before becoming a member.
    - Customer C, who is not a member, earned the fewest points due to fewer purchases.

- If points are earned only after membership:
    - Customer A earned more points than Customer B, indicating higher engagement and spending after joining the membership program.

---

**Question:** 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


**Solution:**

CTE 1: main_sales

- Joins sales, menu, and members
- Uses a `RIGHT JOIN` with members to ensure that only members are included in the points calculation
- Applies a date filter so that only orders on or after the join date are counted
- Groups data by customer
- Calculates total points using a `CASE WHEN` statement:
    - 2× points on all items during the first week after joining (including the join date), where the end of the bonus period is calculated using `DATE_ADD`
    - 2× points for sushi outside the first week
    - Standard points (10 points per $1) for all other items

CTE 2: customers
- Retrieves all customer IDs from the sales table
- Ensures that non-members are also included in the final output

Final Query
- Uses a `LEFT JOIN` to combine customers with main_sales
- Applies `COALESCE` to label customers with no membership data as "not member"

```sql
WITH main_sales as
 (SELECT customer_id, 
        SUM(CASE 
            WHEN order_date >= join_date 
                 AND order_date < DATE_ADD(join_date, INTERVAL 1 WEEK)
                THEN m.price * 20
            WHEN m.product_name = 'sushi'
                THEN m.price * 20
            ELSE m.price * 10
        END) as points
FROM sales as s
JOIN menu m
USING (product_id)
RIGHT JOIN members me
USING (customer_id)
WHERE order_date <= '2021-01-31' 
  AND order_date >= join_date
GROUP BY customer_id),

customers as 
(SELECT customer_id
 FROM sales
 GROUP BY customer_id)
 
SELECT c.customer_id, 
       COALESCE(s.points, 'not member') as points
FROM customers c
LEFT JOIN main_sales s
USING (customer_id)
ORDER BY customer_id;
```
**Output:**
| customer_id | points     |
| ----------- | ---------- |
| A           | 1020       |
| B           | 320        |
| C           | not member |


**Insights:**

- Customer A earned the highest number of points due to:
    - Multiple purchases within the first week after joining, where all items receive 2× points
    - Additional sushi purchases, which continue to earn 2× points even after the first week
- Customer B earned fewer points because:
    - Fewer qualifying orders after joining the program
    - Less benefit from the first-week multiplier compared to A
- Customer C:
    - Never joined the loyalty program, so no points were accumulated

---

### Bonus Questions
**Question:**  Join All The Things

The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | ------------ | ----- | ------ |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |


**Solution:**

- Combined all three tables to have complete order, product, and membership information.
- Used `LEFT JOIN` to include all customers, even those who are not members.
- Selected relevant columns.
- Created a member column using `CASE WHEN` logic:
    - N if the customer has no join_date → not a member.
    - N if the order date is before the membership join date → not a member at that time.
    - Y if the order date is on or after the join date → member.
- Sorted the results by customer_id and order_date for clear chronological order of purchases.

```sql
SELECT 
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE 
        WHEN me.join_date IS NULL THEN 'N'
        WHEN s.order_date < me.join_date THEN 'N'
        ELSE 'Y'
    END AS member
FROM sales s
LEFT JOIN menu m
    USING (product_id)
LEFT JOIN members me
    USING (customer_id)
ORDER BY 
    customer_id,
    order_date;
```
**Output:**

| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | ------------ | ----- | ------ |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

---

**Question:** Rank All The Things

Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

**Solution:**

- Created a `CTE` (agg_sales) with the result from the previous query.
A `temporary table` could have been used, but I chose a CTE for readability and because I didn’t know part of the question would be repeated later.
- In the main query, added a ranking column using `CASE WHEN.`
    - If the customer is a member (member = 'Y'), assign `DENSE_RANK()` over order_date for each customer using a window function.
    - If not a member, the ranking is NULL.
This approach ensures that only purchases made after joining the membership program are ranked, while pre-membership purchases are ignored.

```sql
WITH agg_sales AS (
    SELECT s.customer_id, s.order_date, m.product_name, m.price, 
           CASE 
               WHEN me.join_date IS NULL THEN 'N'
               WHEN s.order_date < me.join_date THEN 'N'
               ELSE 'Y'
           END AS member
    FROM sales s
    LEFT JOIN menu m
    USING(product_id)
    LEFT JOIN members me
    USING (customer_id)
    ORDER BY customer_id, order_date
)
SELECT *, 
       CASE 
           WHEN member = 'Y' THEN  DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
           ELSE NULL
       END AS ranking
FROM agg_sales;
```
**Output:**

| customer_id | order_date | product_name | price | member | ranking |
| ----------- | ---------- | ------------ | ----- | ------ | ------- |
| A           | 2021-01-01 | sushi        | 10    | N      | null    |
| A           | 2021-01-01 | curry        | 15    | N      | null    |
| A           | 2021-01-07 | curry        | 15    | Y      | 1       |
| A           | 2021-01-10 | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01 | curry        | 15    | N      | null    |
| B           | 2021-01-02 | curry        | 15    | N      | null    |
| B           | 2021-01-04 | sushi        | 10    | N      | null    |
| B           | 2021-01-11 | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16 | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01 | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01 | ramen        | 12    | N      | null    |
| C           | 2021-01-01 | ramen        | 12    | N      | null    |
| C           | 2021-01-07 | ramen        | 12    | N      | null    |


---
## 🔹 Overall Summary

This case was relatively straightforward. It reinforced my familiarity with key SQL concepts and techniques.  

- Extensive use of **aggregations** (`SUM`, `COUNT`, `AVG`, `GROUP_CONCAT`) to summarize customer behavior.  
- Application of **window functions** (`RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`) to analyze sequences and ranking of purchases.  
- Implementation of **conditional logic** via `CASE WHEN` for points calculation, membership status, and ranking conditions.  
- Use of **CTEs / temporary tables** to structure queries clearly and improve readability.  
- Use of **correlated subqueries** for specific lookup operations, which worked well for this dataset size.  

Overall, this case strengthened my ability to translate business questions into SQL queries, manipulate and summarize data efficiently, and extract meaningful insights—skills essential for a junior data analyst role.
