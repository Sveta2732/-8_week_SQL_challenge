DROP DATABASE IF EXISTS pizza_runner;
CREATE DATABASE pizza_runner;
USE pizza_runner;

CREATE TABLE runners (
  runner_id INT,
  registration_date DATE
);

INSERT INTO runners VALUES
(1, '2021-01-01'),
(2, '2021-01-03'),
(3, '2021-01-08'),
(4, '2021-01-15');

CREATE TABLE customer_orders (
  order_id INT,
  customer_id INT,
  pizza_id INT,
  exclusions VARCHAR(10),
  extras VARCHAR(10),
  order_time DATETIME
);

INSERT INTO customer_orders VALUES
(1, 101, 1, '', '', '2020-01-01 18:05:02'),
(2, 101, 1, '', '', '2020-01-01 19:00:52'),
(3, 102, 1, '', '', '2020-01-02 23:51:23'),
(3, 102, 2, '', NULL, '2020-01-02 23:51:23'),
(4, 103, 1, '4', '', '2020-01-04 13:23:46'),
(4, 103, 1, '4', '', '2020-01-04 13:23:46'),
(4, 103, 2, '4', '', '2020-01-04 13:23:46'),
(5, 104, 1, 'null', '1', '2020-01-08 21:00:29'),
(6, 101, 2, 'null', 'null', '2020-01-08 21:03:13'),
(7, 105, 2, 'null', '1', '2020-01-08 21:20:29'),
(8, 102, 1, 'null', 'null', '2020-01-09 23:54:33'),
(9, 103, 1, '4', '1,5', '2020-01-10 11:22:59'),
(10, 104, 1, 'null', 'null', '2020-01-11 18:34:49'),
(10, 104, 1, '2,6', '1,4', '2020-01-11 18:34:49');

CREATE TABLE runner_orders (
  order_id INT,
  runner_id INT,
  pickup_time VARCHAR(19),
  distance VARCHAR(10),
  duration VARCHAR(15),
  cancellation VARCHAR(30)
);

INSERT INTO runner_orders VALUES
(1, 1, '2020-01-01 18:15:34', '20km', '32 minutes', ''),
(2, 1, '2020-01-01 19:10:54', '20km', '27 minutes', ''),
(3, 1, '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
(4, 2, '2020-01-04 13:53:03', '23.4', '40', NULL),
(5, 3, '2020-01-08 21:10:57', '10', '15', NULL),
(6, 3, 'null', 'null', 'null', 'Restaurant Cancellation'),
(7, 2, '2020-01-08 21:30:45', '25km', '25mins', 'null'),
(8, 2, '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
(9, 2, 'null', 'null', 'null', 'Customer Cancellation'),
(10, 1, '2020-01-11 18:50:20', '10km', '10minutes', 'null');

CREATE TABLE pizza_names (
  pizza_id INT,
  pizza_name VARCHAR(50)
);

INSERT INTO pizza_names VALUES
(1, 'Meatlovers'),
(2, 'Vegetarian');

CREATE TABLE pizza_recipes (
  pizza_id INT,
  toppings TEXT
);

INSERT INTO pizza_recipes VALUES
(1, '1,2,3,4,5,6,8,10'),
(2, '4,6,7,9,11,12');

CREATE TABLE pizza_toppings (
  topping_id INT,
  topping_name VARCHAR(50)
);

INSERT INTO pizza_toppings VALUES
(1, 'Bacon'),
(2, 'BBQ Sauce'),
(3, 'Beef'),
(4, 'Cheese'),
(5, 'Chicken'),
(6, 'Mushrooms'),
(7, 'Onions'),
(8, 'Pepperoni'),
(9, 'Peppers'),
(10, 'Salami'),
(11, 'Tomatoes'),
(12, 'Tomato Sauce');

UPDATE customer_orders SET exclusions = NULL WHERE exclusions IN ('null', '');
UPDATE customer_orders SET extras = NULL WHERE extras IN ('null', '', 'NaN');

UPDATE runner_orders SET pickup_time = NULL WHERE pickup_time = 'null';
UPDATE runner_orders SET distance = NULL WHERE distance = 'null';
UPDATE runner_orders SET duration = NULL WHERE duration = 'null';
UPDATE runner_orders SET cancellation = NULL WHERE cancellation IN ('null', '');

UPDATE runner_orders
SET distance = REGEXP_SUBSTR(distance, '[0-9]{2}(\\.[0-9]+)?');
UPDATE runner_orders
SET duration = REGEXP_SUBSTR(duration, '[0-9]{2}(\\.[0-9]+)?');
ALTER TABLE runner_orders
MODIFY distance FLOAT;
ALTER TABLE runner_orders
MODIFY duration INT;  