Задание по SQL

1.
select c.country_name,
       count(*) cnt_employyes
from hr.employees e
left join hr.departments d on e.department_id = d.department_id
left join hr.locations l on d.location_id = l.location_id
left join hr.counties c on l.country_id = c.country_id
left join hr.jobs j on e.job_id = j.job_id
left join hr.job_history jh on e.employee_id = jh.employee_id
where j.min_salary > 2000
	and (jh.end_date is null or jh.end_date > current_date)
/* для сотрудников, которые работают на данный момент, должно отсутствовать поле в столбце end_date, т.к. отсутствует столбец с текущим статусом сотрудника,
   либо, если по контракту прописана определенная конечная дата, она должна быть больше сегодняшней */
group by 1
order by 2 desc


2.
select c.cust_first_name,
       c.cust_last_name,
       c.phone_numbers,
       count(*) cnt_orders
from oe.orders o
left join oe.customers c on o.customer_id = c.customer_id
where date_trunc('month', o.order_date) = date_trunc('month', current_date)
group by 1, 2, 3
order by 4 desc
limit 10


3.
with employees_info as (
    select e.employee_id,
           e.first_name employee_first_name,
           e.last_name employee_last_name,
           j.job_title,
           d.department_name,
           r.region_name,
           c.country_name,
           e1.first_name employees_manager_first_name,
           e1.last_name employees_manager_last_name
    from hr.employees e
    left join hr.jobs j on e.job_id = j.job_id
    left join hr.departments d on e.department_id = d.department_id
    left join hr.locations l on d.location_id = l.location_id
    left join hr.counties c on l.country_id = c.country_id
    left join hr.regions r on c.region_id = r.region_id
    left join hr.employees e1 on e.manager_id = e1.employee_id
)
-- с оператором with время обработки запроса будет значительно меньше, чем при соединении left join с каждой таблицей по отдельности
with orders_info as (
    select o.customer_id,
           cnt_orders_last_30_day,
           cnt_orders_last_3_month,
           best_month,
           most_popular_product,
           cnt_above_avg_of_all
    from (
        select o.customer_id,
               sum(case when o.order_date >= current_date - interval '30' day and o.order_status = 1   -- или order_status равняется номеру, который соответсвует статусу "совершен"
                        then 1 else 0 end) cnt_orders_last_30_day,
               sum(case when o.order_date > date_trunc('month', current_date) - interval '2' month and o.order_status = 1
                        then 1 else 0 end) cnt_orders_last_3_month,   -- например, по текущей дате за 3 последних месяца - это с 1 марта по сегодня
               sum(case when o.order_total > avg_total then 1 else 0 end) cnt_above_avg_of_all
        from oe.orders o
        left join (
            select avg(o2.order_total) avg_total
            from oe.orders o2
            where o2.order_date >= current_date - interval '1' year
        ) o2 on true
        where o.order_date <= current_date
        group by 1
        order by 2 desc
    ) o
    left join lateral (
        select o1.customer_id,
               to_char(o1.order_date, 'Month') best_month,
               count(*) cnt_per_month
        from oe.orders o1
        where o1.order_date >= date_trunc('month', current_date) - interval '11' month
            and o1.order_date <= current_date
            and o.customer_id = o1.customer_id
        group by 1, 2
        order by 3 desc
        limit 1
    ) o1 on true
    left join lateral (
        select o1.customer_id,
               p.product_name most_popular_product,
               count(*) cnt_products
        from oe.orders o3
        left join oe.order_items oit on o3.order_id = oit.order_id
        left oe.product_information p on p.product_id = oit.product_id
        where o3.order_date >= current_date - interval '1' month
            and o3.order_date <= current_date
            and o.customer_id = o3.customer_id
        group by 1, 2
        order by 3 desc
        limit 1
    ) o3 on true
)
select c.cust_first_name,
       c.cust_last_name,
       ei.employee_first_name,
       ei.employee_last_name,
       ei.job_title,
       ei.department_name,
       ei.region_name,
       ei.country_name,
       ei.employees_manager_first_name,
       ei.employees_manager_last_name,
       cnt_orders_last_30_day
       cnt_orders_last_3_month,
       best_month,
       most_popular_product,
       cnt_above_avg_of_all
from orders_info oi
left join employees_info ei on o.sales_rep_id = ei.employee_id
left join oe.customers c on oi.customer_id = c.customer_id


