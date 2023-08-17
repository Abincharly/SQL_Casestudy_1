CREATE SCHEMA dannys_diner;
USE dannys_diner;

-- Create and insert into the 'sales' table
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
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

-- Create and insert into the 'menu' table
CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);

-- Create and insert into the 'members' table
CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');



-- 1. What is the total amount each customer spent at the restaurant? 
SELECT S.customer_id, SUM(M.price) AS total_amount
FROM sales S
JOIN menu M ON S.product_id = M.product_id
GROUP BY S.customer_id;


-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS total_visit
FROM sales 
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?
WITH CTE AS (
  SELECT S.customer_id, M.product_name,
    DENSE_RANK() OVER (PARTITION BY S.customer_id ORDER BY S.order_date ASC) AS rnk
  FROM sales S 
  JOIN menu M ON S.product_id = M.product_id
)
SELECT customer_id, product_name
FROM CTE
WHERE rnk = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT M.product_name, count(*) AS total_count
FROM menu M
JOIN sales S ON M.product_id = S.product_id
GROUP BY M.product_name
ORDER BY total_count DESC
LIMIT 1;



-- 5. Which item was the most popular for each customer?
WITH popular_item AS (
SELECT S.customer_id, M.product_name, COUNT(*) AS total_count,
         RANK() OVER (PARTITION BY S.customer_id ORDER BY COUNT(*) DESC) AS rnk
  FROM menu M
  JOIN sales S ON M.product_id = S.product_id
  GROUP BY S.customer_id, M.product_name)
SELECT customer_id, product_name, total_count
FROM popular_item
WHERE rnk = 1;



-- 6. Which item was purchased first by the customer after they became a member?
WITH first_product AS (
SELECT S.customer_id, M.product_name, S.order_date,
ROW_NUMBER() OVER (PARTITION BY S.customer_id ORDER BY S.order_date) AS rnk
FROM sales S 
JOIN menu M ON S.product_id = M.product_id
JOIN members E ON S.customer_id = E.customer_id
WHERE S.order_date >= E.join_date)
SELECT customer_id, product_name, order_date
FROM first_product
WHERE rnk = 1;


-- 7. Which item was purchased just before the customer became a member?
WITH last_product AS (
SELECT S.customer_id, M.product_name, S.order_date,
DENSE_RANK() OVER (PARTITION BY S.customer_id ORDER BY S.order_date) AS rnk
FROM sales S 
JOIN menu M ON S.product_id = M.product_id
JOIN members E ON S.customer_id = E.customer_id
WHERE S.order_date < E.join_date)
SELECT customer_id, product_name, order_date
FROM last_product
WHERE rnk = 1;


-- 8. What is the total items and amount spent for each member before they became a member?
WITH CTE AS (
  SELECT S.customer_id, COUNT(*) AS total_item, SUM(M.Price) AS total_amount
  FROM sales S 
  JOIN menu M ON S.product_id = M.product_id
  JOIN members E ON S.customer_id = E.customer_id
  WHERE S.order_date < E.join_date
  GROUP BY S.customer_id
)
SELECT customer_id, total_item, total_amount
FROM CTE;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT S.customer_id, SUM(
  CASE WHEN S.product_id = 1 THEN (20 * M.Price)
       ELSE (10 * M.Price)
  END) AS total_points
FROM sales S
JOIN menu M ON S.product_id = M.product_id
GROUP BY S.customer_id;



-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH dates AS 
(
   SELECT *, 
   DATE_ADD(join_date, INTERVAL 6 DAY) AS valid_date, 
   LAST_DAY('2021-01-31') AS last_date
   FROM members 
)
SELECT S.customer_id, 
       SUM(
         CASE 
           WHEN S.order_date BETWEEN D.join_date AND D.valid_date THEN M.price * 20
           ELSE M.price * 10
         END 
       ) AS Points
FROM dates D
JOIN sales S ON D.customer_id = S.customer_id
JOIN menu M ON M.product_id = S.product_id
WHERE S.order_date < D.last_date
GROUP BY S.customer_id;
