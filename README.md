# Instacart Customer Behavior Analysis

**SQL + Python analytics on 3.4M orders, ~200K customers, and ~32M product-level purchases.**

This project turns Instacart transaction data into customer-retention, shopping-behaviour, basket, and product-relationship insights using **MySQL and Python**.

## What I analyzed

- **Retention & lifecycle** — order-level retention, survival curves, customer drop-off
- **Customer behaviour** — order frequency, basket size, reorder ratio, customer lifespan
- **Customer value** — lifetime purchase activity and high-engagement segments
- **Shopping patterns** — ordering hours and temporal behaviour
- **Product relationships** — frequently associated products for cross-sell opportunities
- **Customer features** — RFM-style features, category diversity, order frequency, recency signals

## Dataset

| Scale | Value |
|---|---:|
| Orders | **~3.4M** |
| Customers | **~200K** |
| Product purchases | **~32M** |
| Products | **50K+** |

Core tables: `orders`, `order_products_prior`, `products`, `aisles`, `departments`.

## Technical work

The SQL workflow uses:

**CTEs · Window Functions · Aggregations · CASE logic · Joins · Cohort/retention analysis · Survival analysis · Customer-level feature engineering**

The project builds customer-level features including:

```text
total_orders
max_order_number
customer_lifespan
average_order_gap
max_order_gap
total_products
unique_products
average_basket_size
reorder_ratio
unique_departments
unique_aisles
order_frequency_rate
```

It also derives a customer timeline and **true recency** from cumulative order gaps, then builds survival and hazard-style analyses.

## Key business insights

- The largest customer drop-off occurs early in the ordering lifecycle, making first-order and early-repeat experiences important retention touchpoints.
- Basket size and reorder behaviour provide signals for identifying more engaged customers.
- Product-pair relationships can support cross-selling and recommendation strategies.
- Ordering-time patterns can help identify useful windows for promotions and engagement campaigns.

## Visualizations

![Retention Curve](Screenshot%202026-03-15%20143134.png)

![Survival Analysis](Screenshot%202026-03-15%20143108.png)

![Basket Analysis](Screenshot%202026-03-15%20143158.png)

Additional visual outputs cover ordering time, CLV distribution, and product relationships.

## Repository

```text
instacart-customer-behavior-analysis/
├── instacart-customer-behavior-analysis.sql
├── Screenshot *.png
├── README.md
└── .gitattributes
```

## Run the SQL analysis

1. Load the five Instacart CSV tables into MySQL.
2. Update the local CSV paths in the `LOAD DATA INFILE` statements.
3. Execute the SQL script in sections.
4. Export/query the resulting customer-level and retention tables for visualization.

> The SQL file currently contains Windows/MySQL local file paths by design. Replace those paths with the location of your downloaded Instacart CSV files before running it on another machine.

## Tools

**MySQL · SQL · Python · Pandas · Matplotlib · Jupyter**

## Extensions

- Customer segmentation
- Churn prediction
- Collaborative filtering / recommendation models
- Interactive analytics dashboard
