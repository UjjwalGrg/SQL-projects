# 1 Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select distinct(market) from dim_customer
where region = "APAC" and customer = "Atliq Exclusive";

# 2 What is the percentage of unique product increase in 2021 vs. 2020? The
# final output contains these fields,
# unique_products_2020
# unique_products_2021
# percentage_chg

with cte1 as(
	select count(distinct(product_code)) as unique_products_2020
	from fact_sales_monthly
	where fiscal_year = 2020),

	cte2 as(
	select count(distinct(product_code)) as unique_products_2021
	from fact_sales_monthly
	where fiscal_year = 2021)
    
select *, round(abs(unique_products_2021 - unique_products_2020)*100 / unique_products_2020,2) as percentage_chg
from cte1, cte2;
    
    
# 3 Provide a report with all the unique product counts for each segment and
# sort them in descending order of product counts. The final output contains 2 fields,
# segment
# product_count

select distinct(segment), count(*) as product_count from dim_product
group by segment
order by product_count desc;

# 4 Follow-up: Which segment had the most increase in unique products in
# 2021 vs 2020? The final output contains these fields,
# segment
# product_count_2020
# product_count_2021
# difference

with cte1 as(
	select
		p.segment,
		count(distinct(s.product_code)) product_count_2020
    from fact_sales_monthly s
	join dim_product p
	using (product_code)
	where s.fiscal_year = 2020
	group by p.segment),
cte2 as (
	select
		p.segment,
		count(distinct(s.product_code)) product_count_2021
    from fact_sales_monthly s
	join dim_product p
	using (product_code)
	where s.fiscal_year = 2021
	group by p.segment )
    
select cte1.segment,product_count_2020,product_count_2021, product_count_2021 - product_count_2020 as difference
from cte1,cte2
where cte1.segment = cte2.segment
order by difference desc;


# 5 Get the products that have the highest and lowest manufacturing costs.
# The final output should contain these fields,
# product_code
# product
# manufacturing_cost

select 
	p.product_code,
    p.product,
    m.manufacturing_cost
from dim_product p
join fact_manufacturing_cost m
using (product_code)
where manufacturing_cost=(select max(manufacturing_cost) from fact_manufacturing_cost) or 
	  manufacturing_cost=(select min(manufacturing_cost) from fact_manufacturing_cost)
order by manufacturing_cost desc;
    
# 6 Generate a report which contains the top 5 customers who received an
# average high pre_invoice_discount_pct for the fiscal year 2021 and in the
# Indian market. The final output contains these fields,
# customer_code
# customer
# average_discount_percentage

select i.customer_code, c.customer, round(avg(pre_invoice_discount_pct),4) as average_discount_percentage
from fact_pre_invoice_deductions i
join dim_customer c
using (customer_code)
where fiscal_year = 2021 and market = "India"
group by i.customer_code
order by average_discount_percentage desc limit 5;

# 7 Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.
# This analysis helps to get an idea of low and high-performing months and take strategic decisions.
# The final report contains these columns:
# Month
# Year
# Gross sales Amount

select
	monthname(date) as MONTH,
	year(date) as YEAR,
    round(sum(gross_price * sold_quantity)/1000000,2) as Gross_sales_Amount
from fact_sales_monthly s
join fact_gross_price g
using (fiscal_year, product_code)
join dim_customer c
using (customer_code)
where customer = "Atliq Exclusive"
group by date
order by date, Gross_sales_Amount desc;

# 8 In which quarter of 2020, got the maximum total_sold_quantity? The final
# output contains these fields sorted by the total_sold_quantity,
# Quarter
# total_sold_quantity

select case
	when month(date) in (9,10,11) then "Q1"
    when month(date) in (12,1,2) then "Q2"
    when month(date) in (3,4,5) then "Q3"
    else "Q4"
end as Quarter,
sum(sold_quantity)
from fact_sales_monthly
where fiscal_year = 2020
group by Quarter;


# 9 Which channel helped to bring more gross sales in the fiscal year 2021
# and the percentage of contribution? The final output contains these fields,
# channel
# gross_sales_mln
# percentage

with cte1 as(
select
	channel,
    round(sum(gross_price * sold_quantity)/1000000,2) as Gross_sales_Amount
from fact_sales_monthly s
join fact_gross_price g
using (fiscal_year, product_code)
join dim_customer c
using (customer_code)
where fiscal_year = 2021
group by channel
order by Gross_sales_Amount desc)

select *, round((Gross_sales_Amount*100/ (select sum(Gross_sales_Amount) from cte1)),2) as percentage
from cte1;

# 10 Get the Top 3 products in each division that have a high
# total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
# division
# product_code
# product
# total_sold_quantity
# rank_order

with cte1 as (
select
	p.division, s.product_code, p.product, sum(sold_quantity) as total_sold_quantity,
    dense_rank() over(partition by division order by sum(sold_quantity) desc ) as rank_order
from fact_sales_monthly s
join dim_product p
using (product_code)
where fiscal_year = 2021
group by division, product_code
order by total_sold_quantity desc)

select * from cte1
where rank_order in (1,2,3)
;
