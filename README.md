# Instacart Customer Behavior Analysis (SQL + Python)

What insights can we uncover from **3+ million grocery orders**?

This project analyzes the Instacart Market Basket dataset to understand **customer behavior, retention patterns, shopping habits, and product relationships**.

Using SQL and Python, the project builds a full analytics pipeline including:

• Customer lifecycle and retention analysis
• Basket size and shopping behavior analysis
• Customer lifetime value estimation
• Temporal ordering patterns
• Product recommendation relationships

The goal is to demonstrate how raw transactional data can be transformed into **actionable business insights**.


## Dataset

Dataset used: **Instacart Market Basket Analysis**

Scale of the data:

* ~3.4 million orders
* ~200k customers
* ~32 million product purchases
* 50k+ products

Main tables:

| Table                | Description                      |
| -------------------- | -------------------------------- |
| orders               | Customer order history           |
| order_products_prior | Products purchased in each order |
| products             | Product information              |
| aisles               | Product aisle category           |
| departments          | Product department category      |



## Project Structure

instacart-customer-behavior-analysis

data/
sql/
• data_loading.sql
• feature_engineering.sql
• retention_analysis.sql
• basket_analysis.sql
• recommendation_engine.sql

notebooks/
• visualization.ipynb

visuals/
• retention_curve.png
• basket_distribution.png
• orders_by_hour.png
• clv_distribution.png
• product_pairs.png



## Key Analyses

### 1. Customer Retention Analysis

Analyzed how many users return for additional orders.

Insight:
Customer drop-off is highest after the **first purchase**, suggesting onboarding and first-order experience are critical for retention.

---

### 2. Basket Size Distribution

Measured how many products customers buy per order.

Insight:
Most orders contain **5–15 products**, indicating typical grocery basket behavior.

---

### 3. Customer Lifetime Value (CLV Proxy)

Estimated customer engagement using total products purchased across lifetime.

Insight:
A small group of highly active customers contributes a large portion of total purchases.

---

### 4. Shopping Time Patterns

Analyzed when customers place orders throughout the day.

Insight:
Peak ordering occurs between **late morning and afternoon**, suggesting ideal promotion timing.

---


## Visualizations

The project includes several analytical visualizations built using Matplotlib:

* Customer Retention Curve   
* SURVIVAL RETENTION CURVE
* Basket Size Distribution
* Orders by Hour of Day
* Customer Lifetime Value Distribution
* Product Pair Relationships


## Tools & Technologies

SQL (MySQL)
Python
Pandas
Matplotlib

These tools were used to build an **end-to-end analytics workflow from raw data to insight generation**.



## Key Business Insights

1. The majority of churn occurs after the **first order**, highlighting the importance of improving the initial customer experience.

2. Customers who place larger baskets tend to remain active longer.

3. Grocery purchases show strong product pairing patterns that can be leveraged for **recommendation systems and promotions**.

4. A small segment of highly engaged users drives a disproportionate amount of purchasing activity.



## Future Improvements

Possible extensions to this project include:

* Building a churn prediction model
* Implementing collaborative filtering for product recommendations
* Creating a customer segmentation model
* Deploying a dashboard for real-time analytics




































































