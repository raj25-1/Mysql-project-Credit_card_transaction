create database credit_card;
select*
from credit;

-- write a query to print top 5 cities with highest spends 
-- and their percentage contribution of total credit card spends
    with cte1 as (
    select city,sum(amount) as total_spend
    from credit
    group  by city
    ),
		cte2 as (
        select sum(amount) as total_amount
		from credit
        )
        select cte1.*, ROUND(total_spend*1.0/total_amount*100, 2) as percentage_contribution 
        from cte1
        inner join cte2
        on 1=1
        order by total_spend  desc
        limit 5;
        -- 2- write a query to print highest spend month for each year and amount spent 
		-- in that month for each card type
        with cte1 as(
        select card_type,year(transaction_date) as YT,month(transaction_date) as MT,sum(amount) as total_spend
        from credit
        group by card_type,year(transaction_date),month(transaction_date)
        ),
       cte2 as (
       select*, dense_rank() over(partition by card_type order by total_spend desc) as rn
       from cte1
        )
        select*
        from cte2
        where rn = 1;
	-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of  1,000,000 total spends(We should have 4 rows in the o/p one for each card type)
    
with cte1 as (
select*,sum(amount) over(partition by card_type order by transaction_date,transaction_id) as total_spend
from credit
),
cte2 as(
select*, dense_rank() over(partition by card_type order by total_spend) as rn
from cte1
where total_spend>=1000000
)
select*
from cte2
where rn = 1;
        
-- 4- write a query to find city which had lowest percentage spend for gold card type
with cte as (
select city,card_type,sum(amount) as amount,sum(case when card_type='gold' then amount end) as gold_amount
from credit
group by city,card_type
)
select city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from cte
group by city
having  count(gold_amount) > 0 and sum(gold_amount)>0
order by gold_ratio;
-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte1 as (
select city,exp_type, sum(amount) as total_amount
from credit
group by city, exp_type
),
cte2 as (
select*,
dense_rank() over (partition by city order by total_amount desc) rn_desc,
dense_rank() over (partition by city order by total_amount asc) rn_asc 
from cte1
)
select city,
max(case when rn_asc=1 then exp_type end) as lowest_exp_type,
min(case when rn_desc=1 then exp_type end) as highest_exp_type
from cte2
group by city;
    -- 6- write a query to find percentage contribution of spends by females for each expense type
select exp_type,sum(case when gender = 'F' then amount end)*1.0/sum(amount) as percentage_female_contribution
from credit
group by exp_type
order by percentage_female_contribution desc;
-- 7- which card and expense type combination saw highest month over month growth in Jan-2014
with cte1 as (
select card_type,exp_type,year(transaction_date) YT,month(transaction_date) MT, sum(amount) as total_spend
from credit
group by card_type,exp_type,year(transaction_date),month(transaction_date)
),
cte2 as (
select *, lag(total_spend,1) over(partition by card_type,exp_type order by yt,mt) as prev_month_spend
from cte1
)
select*,(total_spend-prev_month_spend) as mom_growth
from cte2 
where prev_month_spend is not null and yt = 2014 and mt = 1
order by mom_growth desc
limit 1;
-- 8- during weekends which city has highest total spend to total no of transcations ratio 
select city,sum(amount)*1.0/count(1) as ratio
from credit
where dayname(transaction_date) in ('Saturday','Sunday')
group by city
order by ratio desc
limit 1;
-- 9- which city took least number of days to reach its
-- 500th transaction after the first transaction in that city;
with cte1 as(
select*,
row_number() over (partition by city order by transaction_date,transaction_id) as rn
from credit
)
select city, timestampdiff(day,min(transaction_date),max(transaction_date)) as datediff1
from cte1
where rn = 1 or rn = 500
group by city
having count(1) = 2
order by datediff1
limit 1;
