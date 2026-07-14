## Business Problems and Solutions

--Import the dataset and do usual exploratory analysis steps like checking the
--structure & characteristics of the dataset:

--1. Data type of all columns in the "customers" table.
--2. Get the time range between which the orders were placed.


select 
min(order_purchase_timestamp) as start_date,
max(order_purchase_timestamp) as till_date
from orders;


--3. Count the Cities & States of customers who ordered during the given
   --period.


select count(*), c.customer_state, c.customer_city from customers c
left join orders o
on c.customer_id = o.customer_id
where o.order_purchase_timestamp >= (select min(order_purchase_timestamp) from orders)
and o.order_purchase_timestamp <= (select max(order_purchase_timestamp) from orders)
group by c.customer_state, c.customer_city;



--In-depth Exploration:
--1. Is there a growing trend in the no. of orders placed over the past years?


with cte as
		   (
	select DATEPART(year,order_purchase_timestamp) as years,
	count(order_id) as order_placed from orders
	group by DATEPART(year,order_purchase_timestamp)
		   )
select order_placed, years, DENSE_RANK() over (order by years) from cte;


--2. Can we see some kind of monthly seasonality in terms of the no. of orders being placed?


with cte as 
			(
	select DATEPART(month,order_purchase_timestamp)as months, 
	count(order_id) as order_placed
	from orders
	group by DATEPART(month,order_purchase_timestamp)
				)

select order_placed, months, DENSE_RANK() over (order by order_placed) as ranks from cte
order by months;



--3. During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
--          ■ 0-6 hrs : Dawn
--          ■ 7-12 hrs : Mornings
--			■ 13-18 hrs : Afternoon
--			■ 19-23 hrs : Night


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

--3. Evolution of E-commerce orders in the Brazil region:
--   1. Get the month on month no. of orders placed in each state.


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


--   2. How are the customers distributed across all the states?


	select customer_state, count(*) as count_state from customers
	group by customer_state
	order by count_state desc


--4. Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.
--    1. Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only),
--       You can use the "payment_value" column in the payments table to get the cost of orders.


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


--    2. Calculate the Total & Average value of order price and freight for each state.

	
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



--5. Analysis based on sales, freight and delivery time.
--  1. Find the no. of days taken to deliver each order from the order’s purchase date as delivery time. 
--     Also, calculate the difference (in days) between the estimated & actual delivery date of an order.

--	Do this in a single query. 
--	You can calculate the delivery time and the difference between the estimated & actual delivery date using the given formula:
--	■ time_to_deliver = order_delivered_customer_date - order_purchase_timestamp
--	■ diff_estimated_delivery = order_delivered_customer_date - order_estimated_delivery_date


--# Calculate days between purchasing, delivering, and estimated delivery.

SELECT order_id,
DATEDIFF(day, day(order_delivered_customer_date), day(order_purchase_timestamp)) as days_to_delivery,
DATEDIFF(day,day(order_delivered_customer_date), day(order_estimated_delivery_date)) as diff_estimated_delivery
FROM orders;


--  2. Find out the top 5 states with the highest & lowest average freight value.


SELECT top 5 c.customer_state,
AVG(freight_value) as avg_freight_value
FROM orders as o
left JOIN order_items as oi
ON o.order_id = oi.order_id
left JOIN customers as c
ON o.customer_id = c.customer_id
GROUP BY customer_state
ORDER BY avg_freight_value DESC;


--6. Analysis based on the payments:
--  1. Find the month on month no. of orders placed using different payment types.


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


--  2. Find the no. of orders placed on the basis of the payment installments that have been paid.


SELECT payment_installments,
COUNT( DISTINCT order_id ) as num_orders
FROM payments
GROUP BY payment_installments;
