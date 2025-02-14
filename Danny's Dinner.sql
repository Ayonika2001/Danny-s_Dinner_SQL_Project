# Case Study #1 - Danny's Diner

CREATE database dannys_diner;
use dannys_diner;

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
  
CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  # Case Study Questions
-- Each of the following case study questions can be answered using a single SQL statement:

-- 1. What is the total amount each customer spent at the restaurant?
select s.customer_id,sum(mu.price) as total_spent
from sales as s
join menu as mu on mu.product_id=s.product_id
group by s.customer_id;

-- 2. How many days has each customer visited the restaurant?

select customer_id,count(order_date) as total_days
from sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

with first_order as
(select mu.product_id,mu.product_name,s.customer_id,s.order_date,
dense_rank() over(partition by s.customer_id order by s.order_date) as rnk
from menu as mu 
join sales as s on mu.product_id=s.product_id)
select * from first_order
where rnk=1;

-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?

select s.customer_id ,mu.product_name,count(s.product_id) as most_purchased_item
from sales as s 
join menu as mu on s.product_id=mu.product_id
group by s.customer_id ,mu.product_name
order by most_purchased_item desc limit 1;


-- 5.Which item was the most popular for each customer?

with most_popular_item as 
(select mu.product_id,mu.product_name,s.customer_id,
dense_rank() over(partition by s.customer_id order by mu.product_id) as rnk
from sales as s 
join menu as mu on s.product_id=mu.product_id)

select * from most_popular_item
where rnk=1;


-- 6. Which item was purchased first by the customer after they became a member?

with first_purchased_item as(
select s.customer_id,mu.product_id,mu.product_name,s.order_date,m.join_date,
dense_rank() over(partition by s.customer_id  order by s.order_date ) as rnk
from sales as s 
join menu as mu on s.product_id=mu.product_id
join members as m on m.customer_id=s.customer_id
where s.order_date>m.join_date)

select * from first_purchased_item 
where rnk=1 ;

-- 7. Which item was purchased just before the customer became a member?

with purchased_item as(
select s.customer_id,mu.product_name,s.order_date,
dense_rank() over(partition by s.customer_id order by s.order_date desc ) as rnk
from sales as s 
join menu as mu on s.product_id=mu.product_id
join members as m on m.customer_id=s.customer_id
where m.join_date>s.order_date)
select * from purchased_item
where rnk=1 ;


-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id,count(mu.product_id) as total_item,sum(mu.price) as total_amount
from menu as mu 
join sales as s on mu.product_id=s.product_id
join members as m on s.customer_id=m.customer_id
where s.order_date< m.join_date
group by s.customer_id
order by s.customer_id;

-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with points_cte as
(select product_id,
case when product_id=1 then (price*20)
else (price*10) end as points
from menu )

select s.customer_id,sum(pc.points) as total_points
from points_cte as pc 
join sales as s on pc.product_id=s.product_id
group by s.customer_id
order by s.customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points 
-- on all items, not just sushi - how many points do customer A and B have at the end of January?

with sales_with_points as
(select m.customer_id,m.join_date ,s.order_date ,mu.price,
case when s.order_date between m.join_date and date_add( m.join_date,interval 6 day) then (mu.price*2)
else mu.price end as points
from menu as mu
join sales as s on mu.product_id=s.product_id
join members as m on s.customer_id=m.customer_id
where s.order_date<="2021-01-31")

select s.customer_id,sum(swp.points) as total_points
from sales_with_points as swp
join sales as s on swp.customer_id=s.customer_id 
group by s.customer_id;
 
 
 
 -- BONUS QUESTIONS
-- 1. Join All The Things
-- Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

select s.customer_id,s.order_date,m.join_date,mu.product_name,mu.price,
case when s.order_date>=m.join_date then "Y"
when s.order_date<m.join_date then "N"
else "N" end as "member_status"
from menu as mu 
join sales as s on mu.product_id=s.product_id
left join members as m on s.customer_id=m.customer_id
order by s.customer_id;

-- 2.Rank All The Things
-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so 
-- he expects null ranking values for the records when customers are not yet part of the loyalty program.

with customer_data as 
(select s.customer_id,s.order_date,m.join_date,mu.product_name,mu.price,
case when s.order_date>=m.join_date then "Y"
when s.order_date<m.join_date then "N"
else "N" end as member_status
from menu as mu 
join sales as s on mu.product_id=s.product_id
left join members as m on s.customer_id=m.customer_id
order by s.customer_id)

select * ,
case when member_status="N" then "Null"
else 
dense_rank() over(partition by customer_id,member_status order by order_date)
end as ranking
from customer_data;


