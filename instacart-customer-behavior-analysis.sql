CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    eval_set VARCHAR(10),
    order_number INT,
    order_dow INT,
    order_hour_of_day INT,
    days_since_prior_order FLOAT
);

CREATE TABLE order_products_prior (
    order_id INT,
    product_id INT,
    add_to_cart_order INT,
    reordered INT
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255),
    aisle_id INT,
    department_id INT
);

CREATE TABLE aisles (
    aisle_id INT PRIMARY KEY,
    aisle VARCHAR(255)
);

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department VARCHAR(255)
);

SHOW VARIABLES LIKE 'secure_file_priv';

SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

SET GLOBAL max_allowed_packet = 1073741824; -- Set to 1GB
SET GLOBAL net_read_timeout = 600;           -- 10 minutes
SET GLOBAL net_write_timeout = 600;          -- 10 minutes


SET UNIQUE_CHECKS = 0;
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv' 
IGNORE INTO TABLE orders 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' -- Changed to \r\n for Windows CSV files
IGNORE 1 ROWS 
(@order_id, @user_id, @eval_set, @order_number, @order_dow, @order_hour_of_day, @days_since_prior_order) 
SET order_id = @order_id, 
    user_id = @user_id, 
    eval_set = @eval_set, 
    order_number = @order_number, 
    order_dow = @order_dow, 
    order_hour_of_day = @order_hour_of_day, 
    days_since_prior_order = NULLIF(@days_since_prior_order, '');

-- Re-enable checks
SET UNIQUE_CHECKS = 1;
SET FOREIGN_KEY_CHECKS = 1;

SELECT COUNT(*) FROM orders;

SET AUTOCOMMIT = 0;
SET UNIQUE_CHECKS = 0;
SET FOREIGN_KEY_CHECKS = 0;


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_products__prior.csv'
INTO TABLE order_products_prior
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, product_id, add_to_cart_order, reordered); 
-- Removed SET clause because column names match variables; this is faster.

COMMIT;
SET UNIQUE_CHECKS = 1;
SET FOREIGN_KEY_CHECKS = 1;

SELECT COUNT(*) FROM order_products_prior;


ALTER TABLE products MODIFY COLUMN product_name VARCHAR(255);
ALTER TABLE products MODIFY COLUMN product_name TEXT;
TRUNCATE TABLE products;

-- No need for variables (@) if the column order matches the CSV
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_name, aisle_id, department_id);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/aisles.csv'
INTO TABLE aisles
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(aisle_id, aisle);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/departments.csv'
INTO TABLE departments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(department_id, department);


# Count Users by Order Number
SELECT order_number , COUNT(DISTINCT user_id) as user_with_this_order
FROM orders
GROUP BY order_number
ORDER BY order_number;

# Retention Curve (Classic)

SELECT
    o.order_number,
    COUNT(DISTINCT o.user_id) AS retained_users,
    COUNT(DISTINCT o.user_id) /
        (SELECT COUNT(DISTINCT user_id)
         FROM orders
         WHERE order_number = 1) AS retention_rate
FROM orders o
GROUP BY o.order_number
ORDER BY o.order_number;

# Survival Logic
SELECT user_id, MAX(order_number) as maximum_orders
FROM orders
GROUP BY user_id
#ORDER BY maximum_orders ASC                          if i use ORDER BY then it paste the max value to each clumn/user_id which makes query wrong
;

with data as (
		SELECT user_id, MAX(order_number) as maximum_orders
		FROM orders
		GROUP BY user_id)
SELECT maximum_orders, COUNT(user_id) as total_customers
from data
GROUP BY maximum_orders
order BY maximum_orders;


# Lifecycle Funnel (Product Funnel Style)
SELECT
    CASE
        WHEN order_number = 1 THEN 'Order 1'
        WHEN order_number = 2 THEN 'Order 2'
        WHEN order_number = 3 THEN 'Order 3'
        ELSE 'Order 4+'
    END AS lifecycle_stage,
    COUNT(user_id) AS users
FROM orders
GROUP BY lifecycle_stage
ORDER BY MIN(order_number);

SELECT
    user_id, COUNT(order_id) as total_orders
FROM orders
GROUP BY user_id;

SELECT user_id, AVG(o.days_since_prior_order) as avg_gap
from orders o
GROUP BY user_id
# ORDER BY avg_gap DESC
;


with data as (
		SELECT p.order_id, COUNT(p.product_id) as product_count
        from order_products_prior p 
        GROUP BY order_id)
SELECT o.user_id, AVG(product_count) as avg_products_bought
from data d
JOIN orders o
on d.order_id=o.order_id
GROUP BY user_id;


# THAT WAS TRAILER BUDDY NOW LETS DIVE INTO 
# MASTER BUILD — FULL USER FEATURE TABLE

with user_order_stats as (
		SELECT user_id, COUNT(order_id) as total_orders, MAX(order_number) as max_order_number,
				SUM(coalesce(days_since_prior_order,0)) as lifespan,
                AVG(coalesce(days_since_prior_order,0)) AS avg_order_gap,
                MAX(days_since_prior_order) as max_order_gap
		from orders
        GROUP BY user_id),
        
basket_stats as (
		SELECT o.user_id, COUNT(op.product_id) as total_products,
        COUNT(DISTINCT op.product_id) as unique_products,
        COUNT(DISTINCT o.order_id) as total_order_check,
        COUNT(op.product_id)/COUNT(DISTINCT o.order_id) as avg_basket_size,
        sum(op.reordered)/COUNT(op.product_id) as reorder_ratio                  #What % of all items the user ever bought were re-orders?	0.0 = never re-bought anything 0.65 = 65% of items bought were already bought before
        from orders as o
        JOIN order_products_prior as op
        on o.order_id=op.order_id
        GROUP BY user_id),
        
category_diversity as (
			SELECT o.user_id, COUNT(DISTINCT p.department_id) as unique_department,
				COUNT(DISTINCT p.aisle_id) as unique_aisle
                from orders as o
                JOIN order_products_prior op
                on o.order_id=op.order_id
                JOIN products as p
                on op.product_id=p.product_id
                GROUP BY user_id),
                
rfm_features as (
		SELECT user_id, total_orders as frequency,
				lifespan as recency_net,
                total_orders / lifespan as order_frequency_rate
                from user_order_stats
                GROUP BY user_id),

churn_label as (
			SELECT user_id, 
					case WHEN max_order_gap>= 30 then 1
                    else 0 END as churned
			from user_order_stats
            GROUP BY user_id)

SELECT u.user_id, u.total_orders, u.max_order_number, u.lifespan, u.avg_order_gap, u.max_order_gap,
		b.total_products, b.unique_products, b.total_order_check, b.avg_basket_size, b.reorder_ratio,
        c.unique_department, c.unique_aisle,
        r.frequency, r.recency_net, r.order_frequency_rate,
        cl.churned
        from user_order_stats as u
        left join basket_stats as b on u.user_id=b.user_id
        left join category_diversity as c on u.user_id=c.user_id
        left join rfm_features as r on u.user_id=r.user_id 
        left join churn_label as cl on u.user_id=cl.user_id;
            
            
        # Build User Timeline    
		with user_timeline as (
			SELECT user_id, order_number, SUM(coalesce(days_since_prior_order,0) ) OVER(PARTITION BY user_id ORDER BY order_number) as cumulative_days
            FROM orders),
		user_last_day as(
			SELECT user_id, MAX(cumulative_days) as last_day
			FROM user_timeline
			GROUP BY user_id),
		global_max_day as(
			SELECT MAX(last_day) as global_max_day
            from user_last_day)
		SELECT user_id, u.last_day, g.global_max_day, ( g.global_max_day- u.last_day) as true_recency_days
        FROM user_last_day as u
        cross join global_max_day as g;                                          # 🔥 Now you have true recency in days.
        
    # Step 2 — Survival Table ,Survival at order N =Users with max_order >= N    
     with user_lifespan as (
			SELECT user_id, max(order_number) as max_orders
            FROM orders
            GROUP BY user_id),										# What is the highest order number this user ever reached
	order_levels as (
			SELECT DISTINCT order_number as order_numbers,  user_id
            from orders)														# Just a list of all existing order numbers that appear anywhere in the table
	select o.order_numbers, COUNT(u.user_id) as total_users_active
    FROM user_lifespan as u
    LEFT JOIN order_levels as o						# LEFT JOIN is used so that: even if no users reached a very high level → we still get a row with 0
    on u.user_id=o.user_id
    where u.max_orders>=o.order_numbers			# ** Which users have a max_order ≥ this level? That means: this user reached at least this order number (they are still “alive” at this level).
    GROUP BY order_numbers
    ORDER BY order_numbers;
    
    
    # Survival Rate
       with user_lifespan as (
			SELECT user_id, max(order_number) as max_orders
            FROM orders
            GROUP BY user_id),	# What is the highest order number this user ever reached
	total_users as (
			SELECT count(*) as total_customers 
            from user_lifespan),
	order_levels as (
			SELECT DISTINCT order_number as order_numbers
            from orders)														# Just a list of all existing order numbers that appear anywhere in the table
	select o.order_numbers, COUNT(u.user_id)/( SELECT total_customers FROM total_users) as survival_rate
    FROM user_lifespan as u
    LEFT JOIN order_levels as o						# LEFT JOIN is used so that: even if no users reached a very high level → we still get a row with 0
    on u.max_orders>=o.order_numbers			# ** Which users have a max_order ≥ this level? That means: this user reached at least this order number (they are still “alive” at this level).
    GROUP BY order_numbers
    ORDER BY order_numbers;          
  # 🔥 This is your survival curve.      
            

# hazard = churned_at_N / users_alive_at_N  (USE SURVIVAL_TABLE)
with user_lifespan as (
			SELECT user_id, max(order_number) as max_orders
            FROM orders
            GROUP BY user_id),										# What is the highest order number this user ever reached
            
	order_levels as (
			SELECT DISTINCT order_number as order_numbers,  user_id
            from orders),	# Just a list of all existing order numbers that appear anywhere in the table
            
	customers as (select o.order_numbers, COUNT(u.user_id) as total_users_active
    FROM user_lifespan as u
    LEFT JOIN order_levels as o						# LEFT JOIN is used so that: even if no users reached a very high level → we still get a row with 0
    on u.user_id=o.user_id
    where u.max_orders>=o.order_numbers			# ** Which users have a max_order ≥ this level? That means: this user reached at least this order number (they are still “alive” at this level).
    GROUP BY order_numbers
    ORDER BY order_numbers),
    
    churn_level as (select u.max_orders as churn_orders, COUNT(*) as churned_customers
    from user_lifespan as u
    GROUP BY churn_orders)
	
    SELECT cl.churn_orders, c.total_users_active, CONCAT(ROUND((churned_customers*100/c.total_users_active),2),'%') as hazard_rate
    FROM churn_level as cl
    INNER JOIN customers as c
    on cl.churn_orders=c.order_numbers
    GROUP BY churn_orders, total_users_active
    ORDER BY churn_orders;


# Do high loyalty users survive longer?  Join loyalty_segment with survival logic.
WITH reorder_user as (
		SELECT o.user_id, SUM(op.reordered)/COUNT(op.product_id) as reorder_ratio ,max(order_number) as max_orders
        FROM orders as o
        JOIN order_products_prior as op
        on o.order_id=op.order_id
        GROUP BY user_id),
        
user_segment as (SELECT user_id, reorder_ratio, max_orders,
	CASE WHEN reorder_ratio>='0.6' THEN 'HIGH LOYALITY'
		WHEN reorder_ratio>='0.3' THEN 'MEDIUM LOYALITY'
        ELSE 'LOW LOYALITY' END AS CUSTOMER_SEGMENT
        FROM reorder_user
        ),
        
	order_levels as (
			SELECT DISTINCT order_number as order_numbers, user_id
            from orders),														# Just a list of all existing order numbers that appear anywhere in the table
            
 user_lifespan as (
			SELECT user_id, max(order_number) as max_orders
            FROM orders
            GROUP BY user_id),										# What is the highest order number this user ever reached
            
	customers as (select o.order_numbers, COUNT(u.user_id) as total_users_active
    FROM order_levels as o
    LEFT JOIN user_lifespan as u						# LEFT JOIN is used so that: even if no users reached a very high level → we still get a row with 0
    on u.user_id=o.user_id
							# ** Which users have a max_order ≥ this level? That means: this user reached at least this order number (they are still “alive” at this level).
    GROUP BY order_numbers
    ORDER BY order_numbers)
    
    SELECT c.order_numbers, c.total_users_active, s.CUSTOMER_SEGMENT
    FROM customers as c
    JOIN user_segment as s
    on  s.max_orders  >= c.order_numbers 
    where CUSTOMER_SEGMENT='HIGH LOYALITY'
    GROUP BY order_numbers, CUSTOMER_SEGMENT
    ORDER BY order_numbers;


# Segment by: High Basket Size vs Low Basket Size , Category Diversity Segmentation, Purchase Speed Segmentation 
with basket_size as(
	SELECT o.user_id, AVG(total_products) as avg_basket_size
    from (
		select order_id, count(product_id) as total_products
        from order_products_prior as op
        GROUP BY order_id)t
	join orders as o
    on o.order_id=t.order_id
	GROUP BY o.user_id),
    
            
category_diversity as (
		SELECT o.user_id, count(distinct p.department_id) as total_departments
        from orders as o
        join order_products_prior as op
        on op.order_id=o.order_id
        join products as p
        on op.product_id=p.product_id
        GROUP BY o.user_id),
        
            
purchase_speed as (
		SELECT o.user_id, avg(days_since_prior_order) as avg_days_bw_orders
        FROM orders as o
        group by user_id)

		SELECT b.user_id, 
        
			case when avg_basket_size >=15 then 'HIGH BASKET SIZE'
				when avg_basket_size >=8 then 'MEDIUM BASKET SIZE'	
			ELSE 'LOW BASKET SIZE' 
            END as basket_segment,
 
			case when total_departments >= 10 then 'HIGH EXPLORER'
				when total_departments >= 5 then 'MODERATE EXPLORER'
                ELSE 'LOW EXPLORER'
			END AS diversity_segment
            ,
            
        case when avg_days_bw_orders <=7 then 'FAST BUYERS'
			when avg_days_bw_orders <=14 then 'REGULAR BUYERS'
            ELSE 'SLOW BUYERS'
            END AS speed_segment
            
            
FROM basket_size as b
join  category_diversity as c
on b.user_id=c.user_id
join purchase_speed as p
on c.user_id=p.user_id;


#  --  Then compute survival per segment. for basket_size		
WITH user_lifespan as (
		SELECT o.user_id, max(o.order_number) as max_orders
        from orders as o
        group by user_id),
        
basket_size as(
	SELECT o.user_id, AVG(total_products) as avg_basket_size
    from (
		select order_id, count(product_id) as total_products
        from order_products_prior as op
        GROUP BY order_id)t
	join orders as o
    on o.order_id=t.order_id
	GROUP BY o.user_id),

customer_segments as (SELECT b.user_id, 
			case when avg_basket_size >=15 then 'HIGH BASKET SIZE'
				when avg_basket_size >=8 then 'MEDIUM BASKET SIZE'	
			ELSE 'LOW BASKET SIZE' 
            END as basket_segment
            from basket_size as b)

select c.basket_segment, avg(u.max_orders) as user_avg_lifespan_orders
		from customer_segments as c
        join user_lifespan as u
        on c.user_id=u.user_id
        GROUP BY basket_segment;
            
#  --  Then compute survival per segment. for diff departments	
WITH user_lifespan as (
		SELECT o.user_id, max(o.order_number) as max_orders
        from orders as o
        group by user_id),
        
category_diversity as (
		SELECT o.user_id, count(distinct p.department_id) as total_departments
        from orders as o
        join order_products_prior as op
        on op.order_id=o.order_id
        join products as p
        on op.product_id=p.product_id
        GROUP BY o.user_id),

customer_segments as ( 
		select cd.user_id,
			case when total_departments >= 10 then 'HIGH EXPLORER'
				when total_departments >= 5 then 'MODERATE EXPLORER'
                ELSE 'LOW EXPLORER'
			END AS diversity_segment 
            from category_diversity as cd)

select cs.diversity_segment, avg(u.max_orders) as user_avg_lifespan_orders
		from customer_segments as cs
        join user_lifespan as u
        on cs.user_id=u.user_id
        GROUP BY diversity_segment;


#  --  Then compute survival per segment. for frequency of purchases
WITH user_lifespan as (
		SELECT o.user_id, max(o.order_number) as max_orders
        from orders as o
        group by user_id),
        
purchase_speed as (
		SELECT o.user_id, avg(days_since_prior_order) as avg_days_bw_orders
        FROM orders as o
        group by user_id),

customer_segments as ( 
		select ps.user_id,
		case when avg_days_bw_orders <=7 then 'FAST BUYERS'
			when avg_days_bw_orders <=14 then 'REGULAR BUYERS'
            ELSE 'SLOW BUYERS'
            END AS speed_segment
            from purchase_speed as ps)

select cs.speed_segment, avg(u.max_orders) as user_avg_lifespan_orders
		from customer_segments as cs
        join user_lifespan as u
        on cs.user_id=u.user_id
        GROUP BY speed_segment;
# fast buyers means they come frequently so there avg orders placed will be most similarly basket size large come less and high explorer comes less bcz he already buys multiple products


# FINAL SURVIVAL + HAZARD TABLE of users using diff order_levels
WITH user_lifespan AS (
		SELECT user_id, MAX(order_number) as max_orders
        FROM orders
        GROUP BY user_id),
        
total as (
		SELECT COUNT(*) as total_users
        from user_lifespan),
        
order_levels as(
		SELECT DISTINCT order_number as order_level
        from orders),
        
survival as (
		SELECT ol.order_level, count(u.user_id) as users_alive
        from order_levels as ol
        left join user_lifespan as u
        on u.max_orders >= ol.order_level
        GROUP BY order_level),
        
churn as (
		SELECT max_orders, count(*) as churned_users
        from user_lifespan
        GROUP BY max_orders)
        
SELECT s.order_level, coalesce(s.users_alive,0) as users_alive,
		coalesce(c.churned_users,0) as churned_users,
        coalesce(s.users_alive,0)  / (SELECT total_users from total) as survival_rate,
        coalesce(c.churned_users,0) / coalesce(s.users_alive,0)  as hazard_rate
        from survival AS s
        LEFT JOIN churn as c
        on s.order_level=c.max_orders
        ORDER BY order_level;
        

# PRODUCT CATEGORY LOYALTY ANALYSIS -- Goal: Understand which departments create the most loyal users.
# # Find User’s Favorite Department
with user_dept as(
		SELECT o.user_id, p.department_id, count(*) as purchases
        from orders as o
        join order_products_prior as op
        on o.order_id=op.order_id
        join products as p
        on op.product_id=p.product_id
        GROUP BY user_id, department_id),
        
ranked_dept as (
		SELECT user_id, department_id, purchases, ROW_NUMBER() over (PARTITION BY user_id ORDER BY purchases DESC) as rn
        from user_dept)
        
SELECT user_id, department_id as favourite_department ,purchases
from ranked_dept
WHERE rn=1; 


# Compare Loyalty vs Survival  -- Join with user lifespan.
WITH user_lifespan AS (
		SELECT user_id, MAX(order_number) as total_orders
        FROM orders
        GROUP BY user_id),

user_dept as(
		SELECT o.user_id, p.department_id, count(*) as purchases
        from orders as o
        join order_products_prior as op
        on o.order_id=op.order_id
        join products as p
        on op.product_id=p.product_id
        GROUP BY user_id, department_id),
        
ranked_dept as (
		SELECT user_id, department_id, purchases, ROW_NUMBER() over (PARTITION BY user_id ORDER BY purchases DESC) as rn
        from user_dept),
        
fav_dept as (SELECT user_id, department_id as favourite_department ,purchases
			from ranked_dept
			WHERE rn=1)
            
SELECT favourite_department, avg(total_orders) as average_orders
from user_lifespan as u
JOIN fav_dept as f
on u.user_id=f.user_id
GROUP BY favourite_department
ORDER BY average_orders desc;



# Customer Order Timeline
SELECT user_id, order_number, SUM(days_since_prior_order) OVER (PARTITION BY user_id ORDER BY order_number) as cumulative_days
from orders
;

# First vs Last Order Detection
SELECT user_id, order_number, FIRST_VALUE(order_number) OVER (PARTITION BY user_id ORDER BY order_number) as first_order,
		LAST_VALUE(order_number) OVER (PARTITION BY user_id ORDER BY order_number ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_order
from orders
;

# Previous Order Gap (LAG)
SELECT user_id, order_number, days_since_prior_order, LAG(days_since_prior_order) OVER (PARTITION BY user_id ORDER BY order_number) as prev_gap
from orders
;

# Customer Rank by Order Frequency
SELECT user_id, MAX(order_number) as total_orders
from orders
GROUP BY user_id
ORDER BY total_orders DESC
LIMIT 10;


# Complex CTE Pipelines
# feature engineering pipeline in SQL.
WITH order_users as (
		SELECT user_id, MAX(order_number) as total_orders
from orders
GROUP BY user_id),

basket_size as (
		SELECT op.order_id ,COUNT(op.product_id) as product_count
				FROM order_products_prior as op
       		    GROUP BY  order_id),
        
avg_basket as ( SELECT o.user_id, AVG(b.product_count) as avg_basket_size
				FROM basket_size as b
                JOIN orders as o
                 on b.order_id=o.order_id
                 GROUP BY user_id),
                 
combined as (
			SELECT u.user_id ,u.total_orders, a.avg_basket_size
            FROM order_users as u
            JOIN avg_basket as a
            on u.user_id=a.user_id)

SELECT *
FROM combined;
            


# user_feature_store
# a master SQL pipeline using layered CTEs. This will include: order behavior ,basket behavior with reorder loyalty ,category diversity ,temporal ordering patterns ,lifecycle metrics

with user_order_stats as (
		SELECT user_id, COUNT(order_id) as total_orders, MAX(order_number) as max_order_number,
				SUM(coalesce(days_since_prior_order,0)) as lifespan,
                AVG(coalesce(days_since_prior_order,0)) AS avg_order_gap,
                MAX(days_since_prior_order) as max_order_gap
		from orders
        GROUP BY user_id),
        
basket_stats as (
		SELECT o.user_id, COUNT(op.product_id) as total_products,
        COUNT(DISTINCT op.product_id) as unique_products,
        COUNT(DISTINCT o.order_id) as total_order_check,
        COUNT(op.product_id)/COUNT(DISTINCT o.order_id) as avg_basket_size,
        sum(op.reordered)/COUNT(op.product_id) as reorder_ratio                  #What % of all items the user ever bought were re-orders?	0.0 = never re-bought anything 0.65 = 65% of items bought were already bought before
        from orders as o
        JOIN order_products_prior as op
        on o.order_id=op.order_id
        GROUP BY user_id),
        
category_diversity as (
			SELECT o.user_id, COUNT(DISTINCT p.department_id) as unique_department,
				COUNT(DISTINCT p.aisle_id) as unique_aisle
                from orders as o
                JOIN order_products_prior op
                on o.order_id=op.order_id
                JOIN products as p
                on op.product_id=p.product_id
                GROUP BY user_id),

time_stats as (
			SELECT o.user_id, AVG(o.order_hour_of_day) as avg_order_hour
            from orders AS o
            GROUP BY user_id)
            
SELECT u.user_id, u.total_orders, u.max_order_number, u.avg_order_gap, 
		b.total_products, b.unique_products, b.avg_basket_size, b.reorder_ratio, 
        c.unique_department, c.unique_aisle,
        t.avg_order_hour
FROM user_order_stats as u
LEFT JOIN basket_stats as b		on u.user_id=b.user_id
LEFT JOIN category_diversity as c		on b.user_id=c.user_id
LEFT JOIN time_stats as t		on c.user_id=t.user_id;















































# TABLES FOR MATPLOTLIB CHARTS

SELECT
order_number,
COUNT(DISTINCT user_id) AS users
FROM orders
GROUP BY order_number
ORDER BY order_number;



WITH user_lifespan AS (
		SELECT user_id, MAX(order_number) as max_orders
        FROM orders
        GROUP BY user_id),
        
total as (
		SELECT COUNT(*) as total_users
        from user_lifespan),
        
order_levels as(
		SELECT DISTINCT order_number as order_level
        from orders),
        
survival as (
		SELECT ol.order_level, count(u.user_id) as users_alive
        from order_levels as ol
        left join user_lifespan as u
        on u.max_orders >= ol.order_level
        GROUP BY order_level)
SELECT
order_level,
users_alive
FROM survival;


SELECT
order_id,
COUNT(product_id) AS basket_size
FROM order_products_prior
GROUP BY order_id;


SELECT
order_hour_of_day,
COUNT(*) AS orders
FROM orders
GROUP BY order_hour_of_day
ORDER BY order_hour_of_day;


SELECT
o.user_id,
COUNT(op.product_id) AS lifetime_products
FROM orders o
JOIN order_products_prior op
ON o.order_id = op.order_id
GROUP BY o.user_id;




























