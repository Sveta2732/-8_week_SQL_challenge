-- =====================================================================
-- Case Study: Danny's Diner (8 Week SQL Challenge)
-- Author: Svetlana Stepanova
-- Purpose: Answer all business questions related to Danny's Diner.
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


-- Case Study Questions

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- 1 What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, 
       CONCAT('$', SUM(m.price)) AS total_amount
FROM sales s 
JOIN menu m
USING (product_id)
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 2 How many days has each customer visited the restaurant?
SELECT customer_id, 
       CONCAT(COUNT(DISTINCT order_date), ' days') as number_of_days
FROM sales
GROUP BY customer_id
ORDER BY customer_id;

-- 3 What was the first item from the menu purchased by each customer?

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


-- 4 What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT (SELECT m.product_name
        FROM menu m
        WHERE s.product_id =m.product_id) AS product_name,
        COUNT(*) AS times_was_purchased
FROM sales s
GROUP BY product_id
ORDER BY times_was_purchased DESC
LIMIT 1;

-- 5 Which item was the most popular for each customer?

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


-- 6 Which item was purchased first by the customer after they became a member?

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


-- 7 Which item was purchased just before the customer became a member?
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
 
 -- 8 What is the total items and amount spent for each member before they became a member?

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

 -- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

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

-- 10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


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

-- Bonus Questions
-- Join All The Things
-- The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

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

-- Rank All The Things
-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

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
           WHEN member = 'Y' THEN DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
           ELSE NULL
       END AS ranking
FROM agg_sales;