/* Create a new database/schema
here eat_at_dannys used as name of schema */ 
create schema eat_at_dannys;

-- Using eat_at_dannys database.
use eat_at_dannys;

-- Creating tables to store data
create table sales(
customer_id varchar(1),
order_date date,
product_id integer);

create table menu(
product_id integer,
product_name varchar(6),
price integer);

create table members(
customer_id varchar(1),
join_date date);

-- Inserting data into tables
insert into sales(
customer_id,order_date,product_id)
values
('A','2021-01-01','1'),
('A','2021-01-01','2'),
('A','2021-01-07','2'),
('A','2021-01-10','3'),
('A','2021-01-11','3'),
('A','2021-01-11','3'),
('B','2021-01-01','2'),
('B','2021-01-02','2'),
('B','2021-01-04','1'),
('B','2021-01-11','1'),
('B','2021-01-16','3'),
('B','2021-02-01','3'),
('C','2021-01-01','3'),
('C','2021-01-01','3'),
('C','2021-01-07','3');

 
insert into menu(
product_id,product_name,price)
values
('1','Sushi','10'),
('2','Curry','15'),
('3','Ramen','12');


insert into members(
customer_id,join_date)
values
('A','2021-01-07'),
('B','2021-01-09');

-- CASE STUDY QUESTIONS
-- 1. What is the total amount each customer spent at the restaurant?
use eat_at_dannys;
select customer_id,sum(price) as total_sales
from sales
join menu on
sales.product_id = menu.product_id
group by customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id, count(distinct(order_date)) as days_visit
from sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
with cte1 as(
select customer_id, order_date, product_name,
dense_rank() over(partition by s.customer_id order by s.order_date asc)
as ranks
 from sales as s
 join menu as m
 on s.product_id = m.product_id)
 
 select customer_id,product_name
 from cte1
 where ranks = 1
 group by customer_id,product_name;
 
 -- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
 select m.product_name,count(*) as most_purchased_item
 from sales as s
 join menu as m
 on m.product_id = s.product_id
 group by product_name
 order by most_purchased_item desc limit 1;
 
 -- 5. Which item was the most popular for each customer?
 with cte1 as(
 select m.product_name,s.customer_id,count(m.product_id) as popular_item,
 dense_rank() over(partition by s.customer_id
 order by count(s.customer_id) desc) as ranks
 from menu as m
 join sales as s
 on m.product_id = s.product_id
 group by customer_id,product_name
 )
 select customer_id,product_name,popular_item
 from cte1
 where ranks = 1;
 
 -- 6. Which item was purchased first by the customer after they became a member?
with cte1 as(
select m.customer_id, m2.product_name,
dense_rank() over(partition by m.customer_id
order by s.order_date) as ranks
from members as m
join sales as s on s.customer_id = m.customer_id
join menu as m2 on s.product_id = m2.product_id
where s.order_date >= m.join_date
)
select customer_id,product_name
from cte1
where ranks = 1;

-- 7. Which item was purchased just before the customer became a member?
with cte1 as(
select m.customer_id,m2.product_name,dense_rank()
over(partition by m.customer_id
order by s.order_date desc) as ranks
from members as m
join sales as s on s.customer_id = m.customer_id
join menu as m2 on s.product_id = m2.product_id
where s.order_date < m.join_date
)
select customer_id,product_name
from cte1
where ranks = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
with cte1 as(
select m.customer_id,count(m2.product_id) as total_items,
sum(m2.price) as total_spent
from members as m
join sales as s on s.customer_id = m.customer_id
join menu as m2 on s.product_id = m2.product_id
where s.order_date < m.join_date
group by customer_id
)
select * from cte1
order by customer_id;
 
 -- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
 with cte1 as(
 select m.customer_id,sum(case
 when m2.product_name = 'Sushi' then(m2.price * 20)
 else (m2.price * 10)
 end) as points
 from members as m
 join sales as s on s.customer_id = m.customer_id
 join menu as m2 on s.product_id = m2.product_id
 group by customer_id
 )
 select * from cte1
 order by customer_id;
 
 -- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
 with cte1 as(
 select m.customer_id,
 sum(case
	when s.order_date < m.join_date then
		case
			when m2.product_name = 'Sushi' then m2.price * 20
			else (m2.price * 10)
		end
	when s.order_date > (m.join_date + 6) then
		case
			when m2.product_name = 'sushi' then m2.price * 20
            else (m2.price * 10)
		end
	else (m2.price * 20)
end) as points
from members as m
join sales as s on s.customer_id = m.customer_id
join menu as m2 on s.product_id = m2.product_id
where s.order_date <= '2021-01-31'
group by customer_id
)
select  * from cte1
order by customer_id;

-- BONUS QUESTIONS
-- Join All The Things - Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)
select s.customer_id,s.order_date,m.product_name,m.price,
case
when m2.join_date > s.order_date then 'N'
when m2.join_date <= s.order_date then 'Y'
else 'N'
end as member_present
from sales as s
left join menu as m on s.product_id = m.product_id
left join members as m2 on s.customer_id = m2.customer_id;

/* Rank All The Things - Danny also requires further information about the ranking of customer products, 
but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records 
when customers are not yet part of the loyalty program. */ 
with cte1 as(
select s.customer_id,s.order_date,m.product_name,m.price,
case
when m2.join_date > s.order_date then 'N'
when m2.join_date <= s.order_date then 'Y'
else 'N'
end as member_present
from sales as s
left join menu as m on s.product_id = m.product_id
left join members as m2 on s.customer_id = m2.customer_id
)
select *, case
when member_present = 'N' then null
else rank() over(partition by customer_id,member_present
order by order_date) end as ranking
from cte1;