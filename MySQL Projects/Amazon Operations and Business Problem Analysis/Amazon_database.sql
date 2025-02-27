#Drop database Amazon_database;

/*Creating database*/
create database Amazon_database;
use Amazon_database;

/*Creating category table*/ 
CREATE TABLE category (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(25)
);
	
/*Creating customers table*/
CREATE table customers(
	customer_id INT PRIMARY KEY,
    f_name VARCHAR(25),
    l_name VARCHAR(25),
    state VARCHAR(25),
    address VARCHAR (25) DEFAULT ('xxxx')
);

/*Creating sellers table*/
CREATE TABLE sellers (
    seller_id INT PRIMARY KEY,
    seller_name VARCHAR(25),
    origin VARCHAR(10)
);

/*Creating products table*/
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    price FLOAT,
    cogs FLOAT,
    category_id INT,
    FOREIGN KEY (category_id)
        REFERENCES category (category_id)
        ON DELETE CASCADE
);

/*Creating orders table*/
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE,
    customer_id INT,
    seller_id INT,
    order_status VARCHAR(20),
    FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON DELETE CASCADE,
    FOREIGN KEY (seller_id)
        REFERENCES sellers (seller_id)
        ON DELETE CASCADE
);

/*Creating order_items table*/
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    price_per_unit FLOAT,
    FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE CASCADE,
    FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE CASCADE
);

/*Creating payments table*/
CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    order_id INT,
    payment_date DATE,
    payment_status VARCHAR(20),
    FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE CASCADE
);

/*Creating shippings table*/
CREATE TABLE shippings (
    shipping_id INT PRIMARY KEY,
    order_id INT,
    shipping_date DATE,
    return_date VARCHAR(20),
    shipping_providers VARCHAR(25),
    delivery_status VARCHAR(25),
    FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE CASCADE
);

/*Creating inventory table*/
CREATE TABLE inventory (
    inventory_id INT PRIMARY KEY,
    product_id INT,
    stock INT,
    warehouse_id INT,
    last_stock_date DATE,
    FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE CASCADE
);

/* Selecting contents from the table*/
SELECT 
    *
FROM
    category;
SELECT 
    *
FROM
    customers;
SELECT 
    *
FROM
    sellers;
SELECT 
    *
FROM
    products;
SELECT 
    *
FROM
    orders;
SELECT 
    *
FROM
    order_items;
SELECT 
    *
FROM
    payments;
SELECT 
    *
FROM
    shippings;
SELECT 
    *
FROM
    inventory;

/*Changing the datatype of return_date column from shipping table*/
SELECT 
    return_date
FROM
    shippings;

UPDATE shippings 
SET 
    return_date = STR_TO_DATE(return_date, '%Y-%m-%d');
    
ALTER TABLE shippings MODIFY return_date DATE;

UPDATE shippings 
SET 
    return_date = NULL
WHERE
    return_date = 0000 - 00 - 00;


/*
1. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold,
and total sales value.
*/
SELECT 
    *
FROM
    order_items;

ALTER TABLE order_items
ADD COLUMN total_sale FLOAT;

UPDATE order_items 
SET 
    total_sale = quantity * price_per_unit;

SELECT 
    order_items.product_id,
    products.product_name,
    SUM(order_items.total_sale) AS total_sales_value,
    COUNT(orders.order_id) AS total_quantity_sold
FROM
    orders
        JOIN
    order_items ON order_items.order_id = orders.order_id
        JOIN
    products ON products.product_id = order_items.product_id
GROUP BY order_items.product_id , products.product_name
ORDER BY total_sales_value DESC
LIMIT 10;

/*
2. Revenue by Category
Calculate total revenue generated by each product category.
Challenge: Include the percentage contribution of each category
to total revenue.
*/

SELECT 
    category.category_id,
    category.category_name,
    SUM(order_items.total_sale) AS total_sales_value,
    SUM(order_items.total_sale) / (SELECT 
            SUM(total_sale)
        FROM
            order_items) * 100 AS contribution
FROM
    order_items
        JOIN
    products ON order_items.product_id = products.product_id
        JOIN
    category ON category.category_id = products.category_id
GROUP BY category.category_id , category.category_name
ORDER BY total_sales_value DESC;

/*
3. Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders.
*/

SELECT 
    customers.customer_id,
    customers.f_name,
    customers.l_name,
    COUNT(order_items.order_id) AS orders_count,
    SUM(order_items.total_sale) AS total_spent,
    SUM(order_items.total_sale) / COUNT(order_items.order_id) AS AOV
FROM
    customers
        JOIN
    orders ON customers.customer_id = orders.customer_id
        JOIN
    order_items ON order_items.order_id = orders.order_id
GROUP BY customers.customer_id , customers.f_name , customers.l_name
HAVING COUNT(order_items.order_id) > 5;
 
/*
4. Monthly Sales Trend
Query monthly total sales over the past year.
Challenge: Display the sales trend, grouping by month, 
return current_month sale, last month sale!
*/

SELECT
 year,
 month,
 total_sale as current_month_sale,
 LAG(total_sale, 1) OVER(ORDER BY year, month) as last_month_sale
FROM 
(SELECT  
 EXTRACT(MONTH FROM orders.order_date) as month,
 EXTRACT(YEAR FROM orders.order_date)as year,
 ROUND(SUM(order_items.total_sale), 2) as total_sale
FROM orders
JOIN order_items
ON orders.order_id = order_items.order_id
WHERE order_date >= CURRENT_DATE - INTERVAL '1' year 
GROUP BY 1, 2
ORDER BY year, month) as t1;

/*
5. Customers with No Purchases
Find customers who have registered but never placed an order.
Challenge: List customer details and the time since 
their registration.
*/

SELECT 
    *
FROM
    customers
WHERE
    customer_id NOT IN (SELECT DISTINCT
            customer_id
        FROM
            orders);
 
SELECT 
    *
FROM
    customers
        LEFT JOIN
    orders ON customers.customer_id = orders.customer_id
WHERE
    orders.customer_id IS NULL;

/*
6. Least-Selling Categories by State
Identify the least-selling product category for each state.
Challenge: Include the total sales for that category 
  within each state.
*/

WITH ranking_table
AS
(SELECT 
customers.state,
category.category_name,
SUM(order_items.total_sale) as total_sales,
RANK() OVER(PARTITION BY customers.state ORDER BY SUM(order_items.total_sale) ASC) as ranking
FROM category
JOIN products
ON category.category_id = products.category_id
JOIN order_items
ON order_items.product_id = products.product_id
JOIN orders
ON orders.order_id = order_items.order_id
JOIN customers
ON customers.customer_id = orders.customer_id
GROUP BY state, category_name
)
SELECT * FROM ranking_table
WHERE ranking = 1;


/*
7. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer 
over their lifetime.
Challenge: Rank customers based on their CLTV.
*/

SELECT 
customers.customer_id,
customers.f_name, 
customers.l_name, 
SUM(order_items.total_sale) as CLTV,
DENSE_RANK() OVER(ORDER BY SUM(order_items.total_sale) DESC) as c_ranking
FROM customers
JOIN orders
ON customers.customer_id = orders.customer_id
JOIN order_items
ON order_items.order_id = orders.order_id
GROUP BY customers.customer_id, customers.f_name, customers.l_name;

/*
8. Inventory Stock Alerts
Query products with stock levels below a certain threshold 
(e.g., less than 10 units).
Challenge: Include last restock date and warehouse information.
*/

SELECT 
    products.product_name,
    inventory.stock,
    inventory.warehouse_id,
    inventory.last_stock_date
FROM
    products
        JOIN
    inventory ON products.product_id = inventory.product_id
WHERE
    inventory.stock < 10;

/*
9. Shipping Delays
Identify orders where the shipping date is later 
than 3 days after the order date.
Challenge: Include customer, order details, 
and delivery provider.
*/

SELECT 
    customers.*,
    orders.*,
    shippings.shipping_providers,
    shippings.shipping_date,
    shippings.shipping_date - orders.order_date AS time_took_to_ship
FROM
    shippings
        JOIN
    orders ON shippings.order_id = orders.order_id
        JOIN
    customers ON customers.customer_id = orders.customer_id
WHERE
    shippings.shipping_date - orders.order_date > 3;

/*
10. Payment Success Rate 
Calculate the percentage of successful payments 
across all orders.
Challenge: Include breakdowns by payment status 
(e.g., failed, pending).
*/

SELECT 
    payments.payment_status,
    COUNT(*) AS total_count,
    COUNT(*) / (SELECT 
            COUNT(*)
        FROM
            payments) * 100 AS success_rate
FROM
    orders
        JOIN
    payments ON orders.order_id = payments.order_id
GROUP BY payments.payment_status;

/*
11. Top Performing Sellers
Find the top 5 sellers based on total sales value.
Challenge: Include both successful and failed orders, 
and display their percentage of successful orders.
*/

WITH top_sellers
AS
(SELECT 
sellers.seller_id,
sellers.seller_name,
SUM(order_items.total_sale) as total_sales_value
FROM orders
JOIN sellers
ON orders.seller_id = sellers.seller_id
JOIN order_items
ON order_items.order_id = orders.order_id
GROUP BY sellers.seller_id,sellers.seller_name
ORDER BY total_sales_value DESC
LIMIT 5
)
SELECT 
    top_sellers.seller_id,
    top_sellers.seller_name,
    SUM(CASE WHEN orders.order_status = 'Completed' THEN 1 ELSE 0 END) AS Completed_orders,
    SUM(CASE WHEN orders.order_status = 'Cancelled' THEN 1 ELSE 0 END) AS Cancelled_orders,
    COUNT(*) AS Total_orders,
    SUM(CASE WHEN orders.order_status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS successful_order_rate
FROM orders 
JOIN top_sellers ON orders.seller_id = top_sellers.seller_id
WHERE orders.order_status NOT IN ('Inprogress', 'Returned')
GROUP BY top_sellers.seller_id, top_sellers.seller_name;

/*
12. Product Profit Margin
Calculate the profit margin for each product 
(difference between price and cost of goods sold).
Challenge: Rank products by their profit margin, 
showing highest to lowest.
*/

SELECT
products.product_id, 
products.product_name,
SUM(order_items.total_sale - (products.cogs * order_items.quantity)) as profit,
SUM(order_items.total_sale - (products.cogs * order_items.quantity))/SUM(order_items.total_sale) * 100 as profit_margin,
DENSE_RANK() OVER(ORDER BY SUM(order_items.total_sale - (products.cogs * order_items.quantity))/SUM(order_items.total_sale) * 100 DESC) as profit_margin_rank
FROM products
JOIN order_items
ON products.product_id = order_items.product_id
GROUP BY products.product_id, products.product_name;

/*
13. Most Returned Products
Query the top 10 products by the number of returns.
Challenge: Display the return rate as a percentage of 
total units sold for each product.
*/

SELECT 
    products.product_id,
    products.product_name,
    COUNT(*) AS total_units_sold,
    SUM(CASE
        WHEN orders.order_status = 'Returned' THEN 1
        ELSE 0
    END) AS total_returned,
    SUM(CASE
        WHEN orders.order_status = 'Returned' THEN 1
        ELSE 0
    END) / COUNT(*) AS return_rate
FROM
    orders
        JOIN
    order_items ON orders.order_id = order_items.order_id
        JOIN
    products ON products.product_id = order_items.product_id
GROUP BY products.product_id , products.product_name
ORDER BY return_rate DESC;

/*
14. Orders Pending Shipment
Find orders that have been paid but are still pending shipment.
Challenge: Include order details, payment date, 
and customer information.
*/

SELECT 
    customers.*,
    orders.*,
    payments.payment_date,
    payments.payment_status,
    shippings.delivery_status
FROM
    customers
        JOIN
    orders ON customers.customer_id = orders.customer_id
        JOIN
    payments ON payments.order_id = orders.order_id
        JOIN
    shippings ON shippings.order_id = orders.order_id
WHERE
    payments.payment_status = 'Payment Successed'
        AND shippings.delivery_status = 'Shipped';

/*
15. Inactive Sellers
Identify sellers who haven’t made any sales in the last 
6 months.
Challenge: Show the last sale date and total sales 
from those sellers.
*/

WITH t1
AS
(SELECT * 
FROM sellers
where seller_id NOT IN (SELECT seller_id FROM orders where order_date >= CURRENT_DATE - INTERVAL '6' month)
)
SELECT 
orders.order_id,
MAX(orders.order_date) as last_sale_date,
MAX(order_items.total_sale) as last_sale_amount
FROM orders
JOIN t1
ON t1.seller_id = orders.seller_id
JOIN order_items
ON order_items.order_id = orders.order_id
GROUP BY orders.order_id;

/*
16. IDENTITY customers into returning or new
if the customer has done more than 5 return 
categorize them as returning otherwise new
Challenge: List customers id, name, total orders, 
total returns
*/

WITH t1 AS (
    SELECT 
        customers.customer_id,
        customers.f_name,
        customers.l_name,
        COUNT(orders.order_id) AS total_orders,
        SUM(CASE WHEN orders.order_status = 'Returned' THEN 1 ELSE 0 END) AS total_returned
    FROM customers
    JOIN orders ON orders.customer_id = customers.customer_id
    GROUP BY customers.customer_id, customers.f_name, customers.l_name
)
SELECT 
    t1.customer_id,
    t1.f_name,
    t1.l_name,
    t1.total_orders,
    t1.total_returned,
    CASE WHEN t1.total_returned > 5 THEN 'Returning customers' ELSE 'New' END AS clasify_cust
FROM t1;

/*
17. Cross-Sell Opportunities
Find customers who purchased product A but not 
product B (e.g., customers who bought AirPods but not 
AirPods Max).Challenge: Suggest cross-sell opportunities by 
displaying matching product categories.
*/

WITH ProductA_Customers AS (
    SELECT DISTINCT customers.customer_id, customers.f_name, customers.l_name
    FROM customers
    JOIN orders ON customers.customer_id = orders.customer_id
    JOIN order_items ON orders.order_id = order_items.order_id
    JOIN products ON order_items.product_id = products.product_id
    WHERE products.product_name = 'AirPods'
),

ProductB_Customers AS (
    SELECT DISTINCT customers.customer_id
    FROM customers
    JOIN orders ON customers.customer_id = orders.customer_id
    JOIN order_items ON orders.order_id = order_items.order_id
    JOIN products ON order_items.product_id = products.product_id
    WHERE products.product_name = 'AirPods Max'
)

SELECT 
    pac.customer_id,
    pac.f_name,
    pac.l_name,
    p.product_name AS cross_sell_product,
    c.category_name AS cross_sell_category
FROM ProductA_Customers pac
LEFT JOIN ProductB_Customers pbc ON pac.customer_id = pbc.customer_id
JOIN orders o ON pac.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN category c ON p.category_id = c.category_id
WHERE pbc.customer_id IS NULL  -- Customers who did not buy Product B
AND p.product_name != 'AirPods'  -- Exclude Product A itself
AND p.category_id = (SELECT category_id FROM products WHERE product_name = 'AirPods');

/*
18. Top 5 Customers by Orders in Each State
Identify the top 5 customers with the highest number of 
orders for each state.
Challenge: Include the number of orders and total sales 
for each customer.
*/

WITH t1 
AS
(
SELECT 
customers.f_name,
customers.l_name,
customers.state,
COUNT(orders.order_id) as total_orders,
SUM(total_sale) as total_sale,
DENSE_RANK() OVER(PARTITION BY customers.state ORDER BY COUNT(orders.order_id)) AS ranking
FROM orders
JOIN customers
ON orders.customer_id = customers.customer_id
JOIN order_items
ON order_items.order_id = orders.order_id
GROUP BY customers.state, customers.f_name, customers.l_name)

SELECT * 
FROM t1
WHERE ranking <= 5;

/*
19. Revenue by Shipping Provider
Calculate the total revenue handled by each shipping provider.
Challenge: Include the total number of orders handled and 
the average delivery time for each provider.
*/

SELECT 
    shippings.shipping_providers,
    COUNT(orders.order_id) AS orders_handled,
    SUM(order_items.total_sale) AS total_revenue,
    COALESCE(AVG(shippings.return_date - shippings.shipping_date),
            0) AS avg_delivery_time
FROM
    orders
        JOIN
    shippings ON shippings.order_id = orders.order_id
        JOIN
    order_items ON order_items.order_id = orders.order_id
GROUP BY shippings.shipping_providers

/*
20. Top 10 product with highest decreasing revenue ratio 
compare to last year(2022) and current_year(2023)
Challenge: Return product_id, product_name, category_name, 
2022 revenue and 2023 revenue decrease ratio at end Round 
the result

Note: 
Decrease ratio = cr-ls/ls* 100 (cs = current_year ls=last_year)
*/

WITH last_year_sale
AS
(
SELECT 
products.product_id,
products.product_name,
SUM(order_items.total_sale) as revenue
FROM orders
JOIN order_items
ON orders.order_id = order_items.order_id
JOIN products
ON products.product_id = order_items.product_id
WHERE EXTRACT(YEAR FROM orders.order_date) = 2022
GROUP BY products.product_id, products.product_name),

current_year_sale
AS
(SELECT 
products.product_id,
products.product_name,
SUM(order_items.total_sale) as revenue
FROM orders
JOIN order_items
ON orders.order_id = order_items.order_id
JOIN products
ON products.product_id = order_items.product_id
WHERE EXTRACT(YEAR FROM orders.order_date) = 2023
GROUP BY products.product_id, products.product_name)

SELECT 
cs.product_id,
ls.revenue as last_year_revenue,
cs.revenue as current_year_revennue,
ls.revenue - cs.revenue as rev_diff,
ROUND((cs.revenue - ls.revenue)/ls.revenue * 100, 2) as rev_decrease_ratio
FROM last_year_sale as ls
JOIN current_year_sale as cs
ON ls.product_id = cs.product_id
WHERE 
ls.revenue > cs.revenue
ORDER BY 5 DESC
LIMIT 10;

