create database coffee_shop;
use coffee_shop;
select database();

-- Data Cleaning

update shop_sales
set transaction_date = str_to_date(transaction_date,'%d-%m-%Y');

alter table shop_sales
modify column transaction_date date;

alter table shop_sales
modify column transaction_time time;

alter table shop_sales
rename column ï»¿transaction_id to transaction_id;


-- What are the top 5 best-selling products in terms of quantity sold?

select
product_id,
sum(transaction_qty) as total_quantity_sold
from shop_sales
group by product_id
order by total_quantity_sold desc
limit 5;

-- Which store location has the highest revenue over the entire dataset?

select
store_location,
round(sum(transaction_qty * unit_price),2) as total_revenue
from shop_sales
group by store_location
order by total_revenue desc;

-- Calculate the total revenue per month and identify trends.

select
monthname(transaction_date) as month,
round(sum(transaction_qty*unit_price),2) as total_revenue
from shop_sales
group by month
order by
case month
when "January" then 1
when "February" then 2
when "March" then 3
when "April" then 4
when "May" then 5
when "June" then 6
when "July" then 7
when "August" then 8
when "September" then 9
when "October" then 10
when "November" then 11
when "December" then 12
end;

-- Find the top 3 best-selling product categories in each store location.

-- select
-- store_location,
-- product_category,
-- sum(transaction_qty) as total_quantity_sold
-- from shop_sales
-- group by store_location,product_category
-- having product_category in ('Coffee','Tea','Bakery')
-- order by store_location asc,total_quantity_sold desc;

-- OR
with category_rank as
(select
store_location,
product_category,
sum(transaction_qty) as total_quantity_sold,
row_number() over(partition by store_location order by sum(transaction_qty) desc) as category_rank
from shop_sales
group by store_location,product_category)

select
store_location,
product_category,
total_quantity_sold
from category_rank
where category_rank <= 3;

-- What is the average transaction size per store?

select
store_id,
round(avg(transaction_qty*unit_price),2) as average_transaction_size
from shop_sales
group by store_id;

-- Identify the hour of the day with the highest sales volume.

select
hour(transaction_time) as hour_of_day,
round(sum(transaction_qty*unit_price),2) as total_sales
from shop_sales
group by hour_of_day
order by total_sales desc;

-- Calculate the percentage contribution of each product category to total revenue.

select
product_category,
round(((sum(transaction_qty*unit_price))/
(select sum(transaction_qty*unit_price) from shop_sales))*100,2) as revenue_contribution
from shop_sales
group by product_category
order by revenue_contribution desc;

-- Find the store that has the most diverse product sales (sells the most unique product types).

select
store_location,
count(distinct product_type) as total_unique_products
from shop_sales
group by store_location
order by total_unique_products desc;

-- Identify products with the highest revenue per unit sold.

select
product_id,
round(((sum(transaction_qty*unit_price))/sum(transaction_qty)),2) as revenue_per_sold,
dense_rank() over(order by ((sum(transaction_qty*unit_price))/sum(transaction_qty)) desc)
as ranking
from shop_sales
group by product_id;

-- Analyze the week-over-week sales growth rate for the entire dataset.

select
date_sub(transaction_date,interval weekday(transaction_date) day) as start_of_week,
round(sum(transaction_qty*unit_price),2) as total_revenue,
round(((sum(transaction_qty*unit_price) - lag(sum(transaction_qty*unit_price)) over())/
lag(sum(transaction_qty*unit_price)) over())*100,2)
as growth
from shop_sales
group by start_of_week;

-- What is the trend in sales over time?

-- (MOM)

select 
date_format(transaction_date,'%Y-%m-01') as start_of_month,
round(sum(transaction_qty*unit_price),2) as total_sales,
round(((sum(transaction_qty*unit_price)- lag(sum(transaction_qty*unit_price))over())/
lag(sum(transaction_qty*unit_price))over())*100,2)
as `MOM%`
from shop_sales
group by start_of_month;

-- (QOQ)

select
date_format(
date_sub(transaction_date,interval (month(transaction_date)-1)%3 month),
'%Y-%m-01')
as start_of_quarters,
-- case
-- 	when month(transaction_date) between 1 and 3 then date_format(transaction_date,'%Y-01-01')
--     when month(transaction_date) between 4 and 6 then date_format(transaction_date,'%Y-04-01')
--     when month(transaction_date) between 7 and 9 then date_format(transaction_date,'%Y-09-01')
--     else date_format(transaction_date,'%Y-10-01')
-- end
-- as start_of_quarter,
round(sum(transaction_qty*unit_price),2) as total_sales,
round(((sum(transaction_qty*unit_price) - lag(sum(transaction_qty*unit_price))over())/
lag(sum(transaction_qty*unit_price))over())*100,2)
as `QOQ%`
from shop_sales
group by start_of_quarters;

-- (WOW)

select
date_sub(transaction_date, interval weekday(transaction_date) day) as start_of_week,
round(sum(transaction_qty*unit_price),2) as total_sales,
round(((sum(transaction_qty*unit_price) - lag(sum(transaction_qty*unit_price)) over())/
lag(sum(transaction_qty*unit_price)) over())*100,2)
as `WOW%`
from shop_sales
group by start_of_week;

-- What is the trend in sales for different product categories over time?

select
product_category,
date_format(transaction_date,'%Y-%m-01') as start_of_month,
round(sum(transaction_qty*unit_price),2) as total_sales,
ifnull(round(((sum(transaction_qty*unit_price)- lag(sum(transaction_qty*unit_price))over(partition by product_category))/
lag(sum(transaction_qty*unit_price))over(partition by product_category))*100,2),'-')
as `MOM%`
from shop_sales
group by start_of_month,product_category;

-- 	Identify the slowest-selling products based on revenue.

select
product_id,
round(sum(transaction_qty*unit_price),2) as total_sales
from shop_sales
group by product_id
having total_sales < 5000
order by total_sales asc;

-- Determine the day of the week with the highest and lowest sales.

with highest_weekday as 
(select
weekday(transaction_date) as day_of_week,
round(sum(transaction_qty*unit_price),2) as total_sales,
rank() over() as ranking
from shop_sales
group by day_of_week
order by total_sales desc
limit 1),

lowest_weekday as
(select
weekday(transaction_date) as day_of_week,
round(sum(transaction_qty*unit_price),2) as total_sales,
rank() over() as ranking
from shop_sales
group by day_of_week
order by total_sales asc
limit 1)

select
highest_weekday.day_of_week,
highest_weekday.total_sales,
lowest_weekday.day_of_week,
lowest_weekday.total_sales
from highest_weekday
join lowest_weekday
on highest_weekday.ranking = highest_weekday.ranking;

-- Calculate the average transaction amount per customer visit.

select
avg(transaction_qty*unit_price) as average_transaction_amount
from shop_sales;

-- Find the store with the highest average transaction value.

select
store_id,
round(avg(transaction_qty*unit_price),2) as average_transaction_value
from shop_sales
group by store_id
order by average_transaction_value desc
limit 1;

-- Identify seasonal patterns in coffee sales (e.g., summer vs. winter).

select
case
	when month(transaction_date) in (1,2) then  "Winter"
    when month(transaction_date) between 3 and 6 then "Summer"
    else "Others"
end
as season,
round(sum(transaction_qty*unit_price),2) as total_sales
from shop_sales
group by season
order by total_sales desc;

-- What is the distribution of unit prices across different product types?

select
product_type,
max(unit_price) as max_price,
min(unit_price) as min_price,
avg(unit_price) as avg_price,
stddev(unit_price) as price_std_dev,
variance(unit_price) as price_variance
from shop_sales
group by product_type;

WITH Ranked AS (
    SELECT 
        product_type,
        unit_price,
        NTILE(4) OVER (PARTITION BY product_type ORDER BY unit_price) AS quartile
    FROM Shop_Sales
)
SELECT 
    product_type,
    MIN(CASE WHEN quartile = 1 THEN unit_price END) AS Q1,
    MIN(CASE WHEN quartile = 2 THEN unit_price END) AS Q2,
    MIN(CASE WHEN quartile = 3 THEN unit_price END) AS Q3,
    MAX(CASE WHEN quartile = 4 THEN unit_price END) AS Q4
FROM Ranked
GROUP BY product_type;

-- Find the products that contribute to 80% of total revenue (Pareto analysis).

with product_revenue as
(select
product_type,
round(sum(transaction_qty*unit_price),2) as total_revenue
from shop_sales
group by product_type),

ranked_products as
(select 
product_type,
total_revenue,
sum(total_revenue) over() as total,
sum(total_revenue) over(order by total_revenue desc) as cumulative_revenue
from product_revenue)

select
product_type,
total_revenue,
round((cumulative_revenue/total)*100,2) as cumulative_percent
from ranked_products
where (cumulative_revenue/total) <= 0.80;

-- Compare sales patterns between weekdays and weekends across different store locations.


select
store_location,
case
	when weekday(transaction_date) in (5,6) then "Weekend"
    else "Weekday"
end
as week_trend,
round(sum(transaction_qty*unit_price),2) as total_sales
from shop_sales
group by store_location, week_trend
order by store_location;
