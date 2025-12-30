CREATE USER 'app_user'@'localhost' IDENTIFIED BY 'app123';
GRANT ALL PRIVILEGES ON your_database.* TO 'app_user'@'localhost';
FLUSH PRIVILEGES;

ALTER USER 'app_user'@'localhost'
IDENTIFIED WITH mysql_native_password
BY 'app123';

FLUSH PRIVILEGES;

GRANT ALL PRIVILEGES ON walmart_db.* 
TO 'app_user'@'localhost';

FLUSH PRIVILEGES;

GRANT ALL PRIVILEGES ON `walmart_db`.* TO 'app_user'@'localhost';


create database Walmart_db;

# Understanding the data

show tables;

select * from walmart;

select count(*) from walmart;

select distinct payment_method from walmart;

select payment_method , count(*) from walmart
group by payment_method;

select count(distinct Branch) from walmart;


# business problems

# 1.Q find different payment method and number of transactions number of qty sold

select payment_method,
count(*) as no_payments,
sum(quantity) as no_qty_sold
from walmart
group by payment_method;

# 2.Q identified the highest-rated categoryin each branch ,displaying in each branch,category and avg rating

# By using window function

select branch,category,avg_rating
from(
	select
		branch,category,avg(rating) as avg_rating,
        rank()over(partition by branch order by avg(rating)desc) as rnk
	from walmart
    group by Branch,category
    )t
    where rnk = 1;
													
# Without using window function

select branch ,category ,avg(rating) as avg_rating
from walmart
group by Branch,category
having avg(rating) = (
			select max(avg_rating)
            from (
				select avg(rating) as avg_rating
                from walmart w2 
                where w2.branch = walmart.Branch
                group by category
                )x
        );        
        
# 3.Q identify the busiest day for each branch based on the number of transations

DESCRIBE walmart;

SELECT branch, day_name, no_transactions
FROM (
    SELECT 
        branch,
        DAYNAME(STR_TO_DATE(date, '%d/%m/%Y')) AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart
    GROUP BY branch, day_name
) AS ranked
WHERE rnk = 1;

# 4.Q calculate the total quantity of items sold per payment method .list payment method and total_quantity

select 
		payment_method,
		sum(quantity) as total_qty
from walmart
group by payment_method;

# 5.Q Determine the average, minimum, and maximum rating of categories for each city

select 
    category,
    City,
	avg(rating),
    min(rating),
    max(rating)
from walmart
group by category,City;
    
/* 6.Q Calculate the total profit for each category by considering total_profit as 
(unit_price * quantity * profit_margin ) list categories and total_profit,ordered from highest to lowest
*/
select * from walmart;

select category,
		sum(Total) as revenue,
        sum(Total * profit_margin) as profit
from walmart
group by category;

/* 7.Q determine the most common payment method for each branch
display branch and the preferred_payment_method
*/

with  cte
as
(SELECT 
    Branch,
    payment_method,
    COUNT(*) AS total_transactions,
    rank() over (partition by branch order by  COUNT(*) desc ) as rnk
FROM walmart
GROUP BY Branch, payment_method)
select * from cte;

/* Q8: Categorize sales into Morning, Afternoon, and Evening shifts
find out each of the shift and the number of invoices
*/
select * from walmart;
select
	Branch,
    case
		when hour(TIME(time))<12 then "morning"
        when hour(TIME(time)) between 12 and 17 then "afternoon"
        else "evening"
	end as shift,
    count(*) as num_invoices
    from walmart
    group by Branch , shift
    order by Branch , num_invoices desc;
    
    /* Q9: Identify the 5 branches with the highest revenue decrease ratio from last year to current year 
    (e.g., 2022 to 2023) */
    
    -- (rev_2022 - rev_2023) / rev_2022 = revenue decreasing ratio
    
   /* select Branch, sum(total) as revenue
    from walmart
    group by Branch; */  -- but ineed the revenue for the year 2022 and 2023
    select * from walmart
     where year(str_to_date(date ,"%d/%m/%y" )) = 2022;
    
    with revenue_2022
    as(
    select Branch,
			sum(total) as revenue
		from walmart
        where year(str_to_date(date ,"%d/%m/%y" )) = 2022
        group by Branch),
        
revenue_2023
    as(
select Branch,
		sum(total) as revenue
 from walmart
where year(str_to_date(date ,"%d/%m/%y" )) = 2023
group by Branch)

select
		r2022.Branch,
        r2022.revenue as last_year_revenue,
        r2023.revenue as current_year_revenue,
        round( ((r2022.revenue - r2023.revenue)/r2022.revenue) * 100,2 ) as revenue_decreasing_ratio
from revenue_2022 as r2022
join revenue_2023 as r2023
on r2022.Branch = r2023.Branch
where r2022. revenue > r2023. revenue
order by revenue_decreasing_ratio desc
limit 5;