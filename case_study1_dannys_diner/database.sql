-- =====================================================================
--  Database: dannys_diner
--  Case Study: Danny's Diner (8 Week SQL Challenge)
--  Author: Svetlana Stepanova
--  Purpose: Create tables and insert sample data for SQL exercises
--  Tools: MySQL
-- =====================================================================
CREATE DATABASE IF NOT EXISTS dannys_diner;
USE dannys_diner;

-- Table: sales
-- Stores customer orders and product information
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INT
);


INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);
 

-- Table: menu
-- Maps the product_id to the actual product_name and price of each menu item.
CREATE TABLE menu (
  product_id INT,
  product_name VARCHAR(5),
  price INT
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);
  
-- Table: members
-- Captures the join_date when a customer_id joined the beta version of the Danny's Diner loyalty program
CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');