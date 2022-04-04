-- SQL Assignment

-- 1) Write an SQL query to report the managers with at least five direct reports.

select employees.name 
from employees inner join
( select employees.manager_id, count(manager_id) as c from employees
group by manager_id
having c >= 3) as q 
on employees.id=q.manager_id;


/* 2) Write an SQL query to report the nth highest salary from the Employee table. If there is no
nth highest salary, the query should report null. */

select * from
(select employees.salary as getNthHighestSalary
from employees group by salary
order by salary asc 
limit 1 offset 5) as t1
union all select null as salary
limit 1;


/* 3)  Write an SQL query to find the people who have the most friends and the most friends
number. */

select t1.id as id, count(t1.id) as num from
(select requester_id as id from RequestAccepted union all select accepter_id  as id from RequestAccepted) as t1
group by t1.id
order by num desc
limit 1;


/* 4) Write an SQL query to swap the seat id of every two consecutive students. If the number of
students is odd, the id of the last student is not swapped. */

select rank() over (order by swapped.rn) as id, swapped.student from
((select student, (t1.rowN+1) as rn from 
(select *, row_number() over (order by id) as rowN from seat) as t1
where (t1.rowN % 2) = 1)
union all
(select student, (t2.rowN-1) as rn from 
(select *, row_number() over (order by id) as rowN from seat) as t2
where (t2.rowN % 2) = 0)
order  by rn asc) as swapped
order by id asc;


/* 5) Write an SQL query to report the customer ids from the Customer table that bought all the
products in the Product table. */

select b.customer_id from
(select count(*) as count from product) as a
inner join
(select customer_id, count(distinct product_key) as count from customer
group by customer_id) as b
on a.count = b.count;


/* 6) Write an SQL query to find for each user, the join date and the number of orders they made
as a buyer in 2019. */

select user_id as buyer_id , join_date, coalesce(b.orders_in_2019, 0) as orders_in_2019 from
users
left join
(select buyer_id, year(order_date) as y, count(item_id) as orders_in_2019  from orders
where year(order_date)= '2019'
group by buyer_id) as b
on users.user_id=b.buyer_id;


/* 7)Write an SQL query to reports for every date within at most 90 days from today, the
number of users that logged in for the first time on that date. Assume today is 2019-06-30. */

select login_date, count(user_id) as user_count from
(select user_id, activity, min(activity_date) as login_date
from traffic
where activity = 'login'
group by user_id) as a
where DATEDIFF('2019-06-30', login_date) <=90
group by login_date;


/* 8)  Write an SQL query to find the prices of all products on 2019-08-16. Assume the price of all
products before any change is 10. */

select c.product_id, coalesce(new_price, 10) as price from
products as a
inner join 
(select product_id, max(change_date) as change_date
from products
where change_date <= '2019-08-16'
group by product_id) as b
on a.product_id = b.product_id and a.change_date = b.change_date
right join 
(select product_id from products
group by product_id) as c
on b.product_id = c.product_id;


/* 9) Write an SQL query to find for each month and country: the number of approved
transactions and their total amount, the number of chargebacks, and their total amount. */


select a.year, coalesce(b.country,c.country) as country, coalesce(b.approved_count, 0) as approved_count,
 coalesce(b.approved_amount,0) as approved_amount, coalesce(c.chargeback_count, 0) as chargeback_count,
 coalesce(c.chargeback_amount) as chargeback_amount from
(select t.year, t.country from 
(select concat(year(trans_date), '-', month(trans_date)) as year, country  from transactions
union all select concat(year(chargebacks.trans_date), '-', month(chargebacks.trans_date)) as year, country from 
chargebacks left join transactions 
on chargebacks.trans_id = transactions.id) as t
group by t.year, t.country) as a
left join 
(select concat(year(trans_date), '-', month(trans_date)) as year,
country, count(state) as approved_count, sum(amount) as approved_amount 
from transactions
where state='approved'
group by year, country) as b
on a.year = b.year and a.country = b.country
left join
(select concat(year(chargebacks.trans_date), '-', month(chargebacks.trans_date)) as year, 
count(amount) as chargeback_count, 
country, sum(amount) as chargeback_amount from chargebacks
left join transactions
on chargebacks.trans_id = transactions.id
group by year, country) as c
on a.year = c.year and a.country = c.country;



/* 10) Write an SQL query that selects the team_id, team_name and num_points of each team in
the tournament after all described matches. */

alter table matches add host_points int not null default 0,
					add	guest_points int not null default 0;

SET SQL_SAFE_UPDATES = 0;

update matches
set host_points = case 
					when host_goals > guest_goals then 3
                    when host_goals = guest_goals then 1
                    else 0
                    end;
update matches
set guest_points = case
					when host_goals < guest_goals then 3
                    when host_goals = guest_goals then 1
                    else 0
                    end;
                    
select teams.team_id, team_name, coalesce((sum(team_point.num_points)),0) as num_points from
(select host_team as team_id, host_points as num_points from matches
union all select guest_team as team_id, guest_points as num_points from matches) as team_point
right join teams
on team_point.team_id = teams.team_id
group by teams.team_id
order by num_points desc;
