# Target_E-commerce_SQL_project

<img width="598" height="338" alt="images" src="https://github.com/user-attachments/assets/83fbdd48-4e80-4bfc-aaab-12d85220f8ca" />


## Overview
This project provides an end-to-end data analysis of over 100,000 real customer orders to optimize logistics performance, identify revenue-driving consumer habits, and map e-commerce growth across distinct geographic regions.  The core business challenge is to evaluate macro-economic money movement, identify localized supply chain bottlenecks (delivery times vs. estimates), and map consumer seasonality to inform future supply and demand strategies

## Objectives

1. Exploratory Data Analysis
Check the structure and characteristics of the dataset by identifying the data types of all columns in the "customers" table.
 
2. In-depth Trend Exploration
Determine if there is a growing trend in the number of orders placed over past years.

3. Geographic Evolution of Orders
Calculate the month-over-month number of orders placed in each specific state.

4. Economic Impact Analysis
Calculate the percentage increase in the cost of orders from 2017 to 2018, specifically looking only at the months between January and August using the payment_value column.

5. Delivery and Logistics Analysis
Calculate the delivery time (days between order purchase date and actual delivery date) and the difference between the estimated and actual delivery dates within a single query.

6. Payment Method Analysis
Calculate the month-over-month number of orders placed using various payment types.
Target-Problem-Statement.pdf


## Dataset

The data for this project is being attached in this repositry


## Schema

<img width="1093" height="640" alt="Gemini_Generated_Image_tismlktismlktism-1" src="https://github.com/user-attachments/assets/f3217f52-ebdc-4242-ab48-4be11007bb27" />


```sql
CREATE TABLE dbo.customers (
    customer_id VARCHAR(MAX) NULL,
    customer_unique_id VARCHAR(MAX) NULL,
    customer_zip_code_prefix INT NULL,
    customer_city VARCHAR(MAX) NULL,
    customer_state VARCHAR(MAX) NULL
);

CREATE TABLE dbo.geolocation (
    geolocation_zip_code_prefix INT NULL,
    geolocation_lat FLOAT NULL,
    geolocation_lng FLOAT NULL,
    geolocation_city VARCHAR(50) NULL,
    geolocation_state VARCHAR(50) NULL
);

CREATE TABLE dbo.order_items (
    order_id VARCHAR(MAX) NULL,
    order_item_id INT NULL,
    product_id VARCHAR(MAX) NULL,
    seller_id VARCHAR(MAX) NULL,
    shipping_limit_date DATETIME2(7) NULL,
    price FLOAT NULL,
    freight_value FLOAT NULL
);

CREATE TABLE dbo.order_reviews (
    review_id VARCHAR(MAX) NULL,
    order_id VARCHAR(MAX) NULL,
    review_score INT NULL,
    review_comment_title VARCHAR(MAX) NULL,
    review_creation_date DATETIME2(7) NULL,
    review_answer_timestamp DATETIME2(7) NULL
);

CREATE TABLE dbo.orders (
    order_id VARCHAR(MAX) NULL,
    customer_id VARCHAR(MAX) NULL,
    order_status VARCHAR(MAX) NULL,
    order_purchase_timestamp DATETIME NULL,
    order_approved_at DATETIME2(7) NULL,
    order_delivered_carrier_date DATETIME2(7) NULL,
    order_delivered_customer_date DATETIME2(7) NULL,
    order_estimated_delivery_date DATETIME2(7) NULL
);

CREATE TABLE dbo.payments (
    order_id VARCHAR(MAX) NULL,
    payment_sequential INT NULL,
    payment_type VARCHAR(MAX) NULL,
    payment_installments INT NULL,
    payment_value FLOAT NULL
);

CREATE TABLE dbo.products (
    product_id VARCHAR(MAX) NULL,
    product_category VARCHAR(MAX) NULL,
    product_name_length INT NULL,
    product_description_length INT NULL,
    product_photos_qty INT NULL,
    product_weight_g INT NULL,
    product_length_cm INT NULL,
    product_height_cm INT NULL,
    product_width_cm INT NULL
);

CREATE TABLE dbo.sellers (
    seller_id VARCHAR(MAX) NOT NULL,
    seller_zip_code_prefix INT NOT NULL,
    seller_city VARCHAR(MAX) NOT NULL,
    seller_state VARCHAR(50) NOT NULL
);

```
``imported data directly with wizard 
```sql
select * from sellers;
select * from products;
select * from payments;
select * from orders;
select * from order_reviews;
select * from order_items;
select * from customers;
select * from geolocation;
```
## Business Problems and Solutions

--Import the dataset and do usual exploratory analysis steps like checking the
--structure & characteristics of the dataset:

--1. Data type of all columns in the "customers" table.
--2. Get the time range between which the orders were placed.

```sql
select 
min(order_purchase_timestamp) as start_date,
max(order_purchase_timestamp) as till_date
from orders;
```

--3. Count the Cities & States of customers who ordered during the given
   --period.

```sql
select count(*), c.customer_state, c.customer_city from customers c
left join orders o
on c.customer_id = o.customer_id
where o.order_purchase_timestamp >= (select min(order_purchase_timestamp) from orders)
and o.order_purchase_timestamp <= (select max(order_purchase_timestamp) from orders)
group by c.customer_state, c.customer_city;
```


--In-depth Exploration:
--1. Is there a growing trend in the no. of orders placed over the past years?

```sql
with cte as
		   (
	select DATEPART(year,order_purchase_timestamp) as years,
	count(order_id) as order_placed from orders
	group by DATEPART(year,order_purchase_timestamp)
		   )
select order_placed, years, DENSE_RANK() over (order by years) from cte;
```

--2. Can we see some kind of monthly seasonality in terms of the no. of orders being placed?

```sql
with cte as 
			(
	select DATEPART(month,order_purchase_timestamp)as months, 
	count(order_id) as order_placed
	from orders
	group by DATEPART(month,order_purchase_timestamp)
				)

select order_placed, months, DENSE_RANK() over (order by order_placed) as ranks from cte
order by months;
```


--3. During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
--          ■ 0-6 hrs : Dawn
--          ■ 7-12 hrs : Mornings
--			■ 13-18 hrs : Afternoon
--			■ 19-23 hrs : Night

```sql
with cte as 
			(
			select customer_id, order_purchase_timestamp, datepart(hour,order_purchase_timestamp) as hours
			from orders
			)
select 
	CASE 
		when hours between 0 and 6 then 'Dawn'
		when hours between 7 and 12 then 'Mornings'
		when hours between 13 and 18 then 'Afternoon'
		when hours between 19 and 23 then 'Night'	
end as day_time, 
count(customer_id) as count_
from cte 
group by CASE 
		when hours between 0 and 6 then 'Dawn'
		when hours between 7 and 12 then 'Mornings'
		when hours between 13 and 18 then 'Afternoon'
		when hours between 19 and 23 then 'Night'
		end
order by count_	;
```
--3. Evolution of E-commerce orders in the Brazil region:
--   1. Get the month on month no. of orders placed in each state.

```sql
with cte as
	(
	select order_purchase_timestamp,
	DATEFROMPARTS(year(order_purchase_timestamp),MONTH(order_purchase_timestamp),1) as yr,
	DATEPART(month,DATEFROMPARTS(year(order_purchase_timestamp),MONTH(order_purchase_timestamp),1)) as months
	from orders
	)
select months, yr, count(order_purchase_timestamp) from cte
group by yr, months
order by yr, months;
```

--   2. How are the customers distributed across all the states?

```sql
	select customer_state, count(*) as count_state from customers
	group by customer_state
	order by count_state desc
```

--4. Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.
--    1. Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only),
--       You can use the "payment_value" column in the payments table to get the cost of orders.

```sql
with cte as 		
		(
		select datepart(year,order_purchase_timestamp) as yr, cast(sum(payment_value)as decimal(10,2)) as total_sales from orders o
		left join payments p
		on o.order_id = p.order_id
		where DATEPART(year,order_purchase_timestamp) between 2017 and 2018
		and datepart(month,order_purchase_timestamp) between 1 and 8 
		group by  datepart(year,order_purchase_timestamp)
     	)
select yr, total_sales, (total_sales - lead(total_sales) over (order by yr desc))/lead(total_sales) over (order by yr desc)*100
from cte;
```

--    2. Calculate the Total & Average value of order price and freight for each state.

```sql	
	SELECT
	c.customer_state,
	cast(AVG(price)as decimal(10,2)) as avg_price,
	cast(SUM(price)as decimal(10,2)) as sum_price,
	cast(AVG(freight_value)as decimal(10,2)) as avg_freight,
	cast(SUM(freight_value)as decimal(10,2)) as sum_freight
	FROM orders o
	left JOIN order_items oi
	ON o.order_id = oi.order_id
	left JOIN customers c
	ON o.customer_id = c.customer_id
	GROUP BY c.customer_state;
```


--5. Analysis based on sales, freight and delivery time.
--  1. Find the no. of days taken to deliver each order from the order’s purchase date as delivery time. 
--     Also, calculate the difference (in days) between the estimated & actual delivery date of an order.

--	Do this in a single query. 
--	You can calculate the delivery time and the difference between the estimated & actual delivery date using the given formula:
--	■ time_to_deliver = order_delivered_customer_date - order_purchase_timestamp
--	■ diff_estimated_delivery = order_delivered_customer_date - order_estimated_delivery_date


--# Calculate days between purchasing, delivering, and estimated delivery.
```sql
SELECT order_id,
DATEDIFF(day, day(order_delivered_customer_date), day(order_purchase_timestamp)) as days_to_delivery,
DATEDIFF(day,day(order_delivered_customer_date), day(order_estimated_delivery_date)) as diff_estimated_delivery
FROM orders;
```

--  2. Find out the top 5 states with the highest & lowest average freight value.

```sql
SELECT top 5 c.customer_state,
AVG(freight_value) as avg_freight_value
FROM orders as o
left JOIN order_items as oi
ON o.order_id = oi.order_id
left JOIN customers as c
ON o.customer_id = c.customer_id
GROUP BY customer_state
ORDER BY avg_freight_value DESC;
```

--6. Analysis based on the payments:
--  1. Find the month on month no. of orders placed using different payment types.

```sql
SELECT
payment_type,
datepart(YEAR, order_purchase_timestamp) as yr,
dAtepart(MONTH, order_purchase_timestamp) as months,
COUNT(DISTINCT o.order_id) as order_count
FROM orders as o
left JOIN payments as p
ON o.order_id = p.order_id
GROUP BY payment_type, datepart(YEAR, order_purchase_timestamp), dAtepart(MONTH, order_purchase_timestamp)
ORDER BY payment_type, yr, months;
```

--  2. Find the no. of orders placed on the basis of the payment installments that have been paid.

```sql
SELECT payment_installments,
COUNT( DISTINCT order_id ) as num_orders
FROM payments
GROUP BY payment_installments;
```

## Findings and Conclusion
This project is designed to turn raw e-commerce transaction data into actionable business intelligence for Target by revealing growth patterns, customer behavior, and operational inefficiencies. The strongest value of the analysis is that it connects sales trends with logistics and payment behavior, helping the business improve planning, reduce delivery delays, and make better regional decisions.
Target-Problem-Statement.pdf

Overall, the study shows that the dataset is rich enough to answer strategic questions about demand, seasonality, freight cost, delivery speed, and payment preferences, making it a strong portfolio project for SQL-based analytics.




