CREATE database Projects;
use Pizza_sales;
DROP TABLE IF EXISTS pizza_sales;
create table pizza_sales(
pizza_id int,
order_id int,
pizza_name_id text,
quantity int,
order_date text,
order_year int,
order_month	text,
order_time time,
Hour_value int,
Day_part text,
unit_price double,
total_price	double,
pizza_size text ,
pizza_category text,
pizza_ingredients text,
pizza_name text
);
select * from pizza_sales;

LOAD DATA INFILE 'Pizza_sales_updated.csv'
INTO TABLE pizza_sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(pizza_id, order_id, pizza_name_id, quantity, order_date, order_year, order_month,
 order_time, Hour_value, Day_part, unit_price, total_price, pizza_size, 
 pizza_category, pizza_ingredients, pizza_name);

create table pizza_sales_replica
like pizza_sales;

insert into pizza_sales_replica
select * from pizza_sales;

select * from pizza_sales_replica;

-- Which pizzas are frequently ordered together (pair analysis)?

with mpo as(
select order_id, pizza_name
from pizza_sales_replica p 
where p.order_id in
(select order_id
from pizza_sales_replica o
group by 1
having count(*)>1))

select mpo.order_id, group_concat(distinct mpo.pizza_name order by mpo.pizza_name) as pizzas
from mpo
group by 1;

SELECT 
    CONCAT(LEAST(p1.pizza_name, p2.pizza_name), '-', GREATEST(p1.pizza_name, p2.pizza_name)) AS pizza_pair,
    COUNT(*) AS pair_count
FROM pizza_sales_replica p1
JOIN pizza_sales_replica p2
    ON p1.order_id = p2.order_id 
    AND p1.pizza_name < p2.pizza_name  -- Prevent duplicate pairs like (Cheese, Pepperoni) and (Pepperoni, Cheese)
GROUP BY pizza_pair
order by pair_count desc
limit 10;
set @a = (select count(distinct order_id) from pizza_sales_replica);
select @a;

-- What are the top ingredients used in best-sellers?
with tab1 as (
select row_number() over(partition by pizza_ingredients) as rowNum,pizza_ingredients, 
replace(replace(pizza_ingredients,'"',''),'?','') as pizzaIngredients
from pizza_sales_replica),
tab2 as (
select t1.rowNum,t1.pizzaIngredients,jt.pizza_ingred
from tab1 t1, 
json_table(
concat('["',replace(t1.pizzaIngredients,',','","'),'"]'),
"$[*]" columns (pizza_ingred varchar(255) path "$")
) as jt),
tab3 as (
select * from tab2
)
select t3.pizza_ingred, count(*) as ingred_quantity
from tab3 t3
group by t3.pizza_ingred 
order by ingred_quantity desc
limit 10;

-- How many repeat pizzas appear across different orders?

select distinct pizza_name, count(distinct order_id) as number_of_order  
from pizza_sales_replica
group by 1
order by 2 desc;

-- Analyze customer preferences based on pizza size and time of day.

select day_part, pizza_size, count( distinct order_id) as num_of_orders
from pizza_sales_replica
group by 1,2
order by 1;

-- Calculate Month-over-Month (MoM) growth.

with tab as(select order_month, cast(sum(total_price) as decimal(10,0)) as total_rev
from pizza_sales_replica
where order_year=2015
group by 1),
tab1 as (select order_month, total_rev,
lag(total_rev) over(order by  'january','february','March','April','May','June','July','August','September',
'October','November','December' asc) as mom_rev
from tab)
select order_month,total_rev, ((mom_rev-total_rev)/mom_rev)*100 as mom_percentage
from tab1;

-- What is the Revenue per Daypart trend over time?
SELECT 
  order_month,
  Day_part,
  SUM(total_price) AS total_rev
FROM pizza_sales_replica
GROUP BY order_month, Day_part
ORDER BY 
  CASE order_month
    WHEN 'January' THEN 1
    WHEN 'February' THEN 2
    WHEN 'March' THEN 3
    WHEN 'April' THEN 4
    WHEN 'May' THEN 5
    WHEN 'June' THEN 6
    WHEN 'July' THEN 7
    WHEN 'August' THEN 8
    WHEN 'September' THEN 9
    WHEN 'October' THEN 10
    WHEN 'November' THEN 11
    WHEN 'December' THEN 12
  END,
  Day_part;
  
  -- Build a running total (cumulative sum) of revenue by month.
SELECT 
  order_year, 
  order_month,
  SUM(total_price) OVER ( partition by order_year
    ORDER BY 
      CASE order_month
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
      END ASC
  ) AS total_rev
FROM (
  SELECT 
    order_year, 
    order_month, 
    SUM(total_price) AS total_price
  FROM pizza_sales_replica
  WHERE order_year = 2015
  GROUP BY order_year, order_month
) AS monthly_sales;


select distinct order_year, order_month, total_rev 
from
(SELECT 
  order_year, 
  order_month,
  SUM(total_price) OVER (
    ORDER BY 
      CASE order_month
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
      END ASC
  ) AS total_rev
FROM pizza_sales_replica) as tab1;

-- What are the bottom 5 performing pizzas and why?
select pizza_name, cast(sum(total_price) as decimal(10,0)) as totel_rev
from pizza_sales_replica
group by 1
order by 2 asc
limit 5;

select * from pizza_sales_replica;

-- changing order_date column to date from text 
select order_date, str_to_date(order_date,"%d/%m/%Y")
FROM pizza_sales_replica;

ALTER TABLE pizza_sales_replica
add column updated_date date after order_date;

update pizza_sales_replica
set updated_date = str_to_date(order_date,"%d/%m/%Y");

alter table pizza_sales_replica
drop column order_date;

alter table pizza_sales_replica
change column updated_date order_date date;

-- Calculate month-over-month (YoY) growth.
with tab as (
select extract(month from order_date) as ord_month, total_price
from pizza_sales_replica
),

tab1 as(
select ord_month, sum(total_price) over( order by ord_month) as mom_sales
from tab)

select distinct ord_month, mom_sales
from tab1;

select * from pizza_sales_replica;

select dense_rank() over( order by revenue desc) as Rank_by_revenue, Best_Seller, revenue
from(
select distinct pizza_name as best_Seller,round(sum(total_price),0) as revenue
from pizza_sales_replica
group by 1) as t;


Select Rank_by_revenue,order_month, Best_Seller, revenue
from(
select dense_rank() over( partition by month_number order by revenue desc) as Rank_by_revenue,month_number,order_month, Best_Seller, revenue
from(
select pizza_name as best_Seller,EXTRACT(MONTH FROM order_date) as month_number,order_month ,round(sum(total_price),0) as revenue
from pizza_sales_replica
group by 1,2,3) as t) as t1
where Rank_by_revenue in (1,2,3);


select * from pizza_sales_replica;

-- using ntile()
select ntile(11) over(order by revenue desc) as top_To_bottom,pizza_name,revenue
from(
select pizza_name, sum(total_price) as revenue 
from pizza_sales_replica
group by 1) t;

-- using dense_rank()
select revenue,
case
	when top_rank<=3 then pizza_name
    else NULL
    end as top_3_pizza,
case
	when top_rank>3 then pizza_name
    end as other_pizzas

from(
select dense_rank() over( order by revenue desc) as top_rank,pizza_name,revenue
from(
select pizza_name, sum(total_price) as revenue 
from pizza_sales_replica
group by 1) t) as t2;



select pizza_name, ord_number, total_rev,
case
 when ord_number>=2000 then 'Top_seller'
 when ord_number between 1000 and 2000 then 'Mid_seller'
 else 'low_seller'
 end as based_on_number_of_sell
 from
(with tab as (
select pizza_name, count(order_id) as ord_number
from(
select order_id, pizza_name 
from pizza_sales_replica
) t
group by 1
having count(order_id)>=1
),
tab1 as (
select pizza_name,sum( total_price) as total_rev
from pizza_sales_replica
group by 1
)
select tab1.pizza_name,tab.ord_number, tab1.total_rev
from tab1 
join tab on tab.pizza_name=tab1.pizza_name
order by tab.ord_number desc) final;

-- Analyze average revenue per pizza over time.
select order_month, pizza_name,count(order_id) as number_of_order,sum(total_price) as totat_revenue,
avg(total_price) as average_revenue
from pizza_sales_replica
group by 1,2;

select *
from
(select pizza_name, total_orders, total_revenue,Season,
dense_rank() over(partition by Season order by total_revenue desc) as ranks
from
(select pizza_name, total_orders, total_revenue,
case
	when Month_number in(3,4,5) then 'Spring'
    when Month_number in(6,7,8) then 'Summer'
    when Month_number in(9,10,11) then 'Fall'
    else 'winter'
    end as Season
from (
select pizza_name,extract(month from order_date) as Month_number,
sum(quantity) as total_orders,
round(sum(total_price),0) as total_revenue
from pizza_sales_replica
group by 1,2
) tab
) tab2) tab3
where ranks in(1,2,3);

select *
from
(select *,
dense_rank() over(partition by season order by total_orders desc,total_revenue desc ) as top_rank
from
(select pizza_name,
sum(quantity) as total_orders,
sum(total_price) as total_revenue,
season
from
(select pizza_name,
quantity, total_price,
case
	when extract(month from order_date) in (3,4,5) then 'spring'
    when extract(month from order_date) in (6,7,8) then 'summer'
    when extract(month from order_date) in (9,10,11) then 'fall'
    else 'winter'
    end as season
from pizza_sales_replica) base
group by 1,4) final) ranked
where top_rank in (1,2,3)
;

select min(order_date),
pizza_name
from pizza_sales_replica
group by 2;

select max(order_date),
pizza_name
from pizza_sales_replica
group by 2;



