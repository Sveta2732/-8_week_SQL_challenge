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

-- C. Ingredient Optimisation
-- 1 What are the standard ingredients for each pizza?
-- 2 What was the most commonly added extra?
-- 3 What was the most common exclusion?
-- 4 Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-- 5 Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- 6 What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

-- 1 What are the standard ingredients for each pizza?

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

-- 2 What was the most commonly added extra?

-- Create a temporary table for exclusions
DROP TABLE IF EXISTS customer_orders_excl;
CREATE TEMPORARY TABLE customer_orders_excl AS
SELECT p.pizza_number,
       p.order_id,
       p.customer_id,
       p.pizza_id,
       excl.exclusions_num
FROM (SELECT *,
             ROW_NUMBER() OVER() as pizza_number
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

-- 3 What was the most common exclusion?

SELECT exclusions_num,
       (SELECT topping_name 
        FROM pizza_toppings t 
        WHERE t.topping_id = p.exclusions_num) AS topping_name,
       COUNT(exclusions_num) AS used_number
FROM customer_orders_excl p
GROUP BY exclusions_num, topping_name
ORDER BY used_number DESC
LIMIT 1;

-- 4 Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

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

-- 5 Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"  

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

-- 6 What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

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

-- D. Pricing and Ratings
-- 1 If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
-- 2 What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
-- 3 The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
-- 4 Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas
-- 5 If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

-- 1 If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

SELECT CONCAT(SUM(
           CASE 
               WHEN pizza_id = 1 THEN 12
               ELSE 10 
           END), '$') as cost
FROM runner_orders
JOIN customer_orders
USING(order_id)
WHERE cancellation IS NULL;

-- 2 What if there was an additional $1 charge for any pizza extras?

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

-- 3 The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

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

-- 4 Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?

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

-- 5 If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

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

-- E. Bonus Questions
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

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


