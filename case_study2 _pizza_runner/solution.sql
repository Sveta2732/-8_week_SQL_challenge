-- A. Pizza Metrics
-- 1 How many pizzas were ordered?
-- 2 How many unique customer orders were made?
-- 3 How many successful orders were delivered by each runner?
-- 4 How many of each type of pizza was delivered?
-- 5 How many Vegetarian and Meatlovers were ordered by each customer?
-- 6 What was the maximum number of pizzas delivered in a single order?
-- 7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- 8 How many pizzas were delivered that had both exclusions and extras?
-- 9 What was the total volume of pizzas ordered for each hour of the day?
-- 10 What was the volume of orders for each day of the week?


-- 1 How many pizzas were ordered?

SELECT 
    COUNT(pizza_id) AS ordered 
FROM 
    customer_orders;

-- 2 How many unique customer orders were made?

SELECT 
    COUNT(DISTINCT order_id) AS unique_orders
FROM 
    customer_orders;

-- 3 How many successful orders were delivered by each runner?

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

-- 4 How many of each type of pizza was delivered?

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

-- 5 How many Vegetarian and Meatlovers were ordered by each customer?

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

-- 6 What was the maximum number of pizzas delivered in a single order?

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

-- 7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

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

-- 8 How many pizzas were delivered that had both exclusions and extras?

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

-- 9 What was the total volume of pizzas ordered for each hour of the day?

SELECT 
    HOUR(order_time) AS order_hour, 
    COUNT(*) 
FROM 
    customer_orders
GROUP BY 
    HOUR(order_time)
ORDER BY 
    HOUR(order_time);

-- 10 What was the volume of orders for each day of the week?

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

-- B. Runner and Customer Experience
-- 1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
-- 2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- 3 Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- 4 What was the average distance travelled for each customer?
-- 5 What was the difference between the longest and shortest delivery times for all orders?
-- 6 What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- 7 What is the successful delivery percentage for each runner?

-- 1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

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

-- 2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

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
    customer_orders 
USING (order_id)
WHERE 
    cancellation IS NULL
GROUP BY 
    runner_id
ORDER BY 
    runner_id;

-- 3 Is there any relationship between the number of pizzas and how long the order takes to prepare?

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

-- 4 What was the average distance travelled for each customer?

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

-- 5 What was the difference between the longest and shortest delivery times for all orders?

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

-- 6 What was the average speed for each runner for each delivery and do you notice any trend for these values?

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

-- 7 What is the successful delivery percentage for each runner?

SELECT 
    runner_id,
    CONCAT(ROUND(COUNT(duration) / COUNT(*) * 100, 0), '%') AS successful_delivery
FROM 
    runner_orders
GROUP BY 
    runner_id
ORDER BY 
    runner_id;