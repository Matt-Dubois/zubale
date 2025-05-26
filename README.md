# Zubale Technical Challenge

This project contains my solutions for the technical challenges proposed by Zubale. All infrastructure and processing were implemented using Google Cloud Platform (GCP) services and SQL scripts for BigQuery.

---

## 🧩 Challenge 1 – Ingest and Transform Orders

### GCP Setup

To begin, the following GCP resources must be created:

- **BigQuery Dataset**:  
  - Name: `zubale`  
  - Location: US (multi-region)

- **Cloud Storage Buckets**:  
  - `zubale`  
    For storing general files such as the products CSV  
  - `oms-order-creation`  
    This is where our OMS system deposits new order files in `.csv` format  
  - `order-full-results`  
    After validation and cleaning, processed orders are moved here

All buckets use the **Standard** storage class and are located in the **US multi-region**.

---

### Products Pipeline

1. **Create the products table**  
   Run the SQL script: `bigquery/products/1_create_table.sql`

2. **Upload product data**  
   Upload the `products.csv` file into the `zubale` bucket.

3. **Load products into BigQuery**  
   Run: `bigquery/products/2_load_records.sql`

4. **Update or append new product records**  
   When needed, use: `bigquery/products/3_update_table.sql`

> ✅ At this point, your products table is up-to-date and ready to scale as new records or changes come in.

---

### Orders Pipeline

1. **Create the orders table**  
   Run the SQL script: `bigquery/orders/1_create_table.sql`

2. **Deploy Cloud Functions**

   - **order-creation-landing**  
     Triggered whenever a new CSV is deposited into `oms-order-creation`.  
     Cleans and validates the data and moves it to `order-full-results`.

   - **order-creation-processing**  
     Runs every 5 minutes. Loads validated orders from `order-full-results` into BigQuery using `load_jobs`.

> 💡 **Note**: A more scalable and memory-efficient solution—especially for large files—would involve using **Cloud Run with Go**. This would allow true streaming reads from GCS using pointers and buffers, minimizing memory usage (e.g., 128MB for GB-sized files). However, this would exceed the scope of this test.

---

## 🧩 Challenge 2 – Handling Price Conversion Issues

Sometimes the OMS sends order prices in BRL (Brazilian Real) instead of USD. To address this:

You’ll find prepared SQL scripts in the folder: `./bigquery/challenge_2/`

These scripts can:

- Update order prices by date if the issue affected multiple orders
- Update prices by `order_id` for isolated exceptions

> 💡 **Improvement Suggestion**: This logic can be encapsulated in a Cloud Function. It would receive parameters (e.g., date range or order ID) and query an external currency API (e.g., BRL to USD) to perform automatic and real-time corrections.

---

## 🧩 Challenge 3 – BigQuery queries

All related queries and AI-pipeline proposals are stored in the folder: `./bigquery/challenge_3`

---

### 🧩 Challenge 4 – AI-Based Enhancements


1. What other insights do you think would add value to the business that can be extracted using at least one of these tables?
Pick up to three, and explain why they might be useful and how we can get them. (If more tables are needed, list them.)

    ### Category Performance Analysis
    By comparing order volume and revenue by category, we can understand:

    - What categories define our core business
    - Which ones consistently underperform (and may not be worth the effort)
    - Where we might want to invest more marketing or operational focus

    McDonald's didn’t become a giant by offering everything. It succeeded by doing a few things exceptionally well. Similarly, we can assess whether it's more strategic to double down on a few high-performing categories rather than trying to win across the board.

    We can also view this over time. It’s expected that coats will outperform swimsuits in winter, but if sneakers are consistently growing faster than jackets month over month, maybe it’s time to pivot or realign our product strategy)

    ### Average Order Volume and Revenue per Day
    Understanding the average number of orders per day and the average daily revenue gives us foundational KPIs for tracking our business growth. These metrics allow us to:

    - Monitor operational performance over time
    - Set realistic growth targets for the team
    - Optimize pricing, promotions, and customer retention strategies

    In short, they provide high-level visibility into the health of our business and act as a benchmark for improvement.

    ### Top-Selling Products by Revenue and Units
    This insight helps us identify which products are truly resonating with our customers.

    - High units sold might point to affordability or daily utility
    - High revenue might suggest premium products that are still in demand

    Either way, these products represent what works — they are case studies for success. Analyzing them can help us understand whether their performance was driven by product-market fit, a strong campaign, or even seasonality. These are the products we should learn from — they set the standard for our brand.

    ### Price Sensitivity per Product
    Price sensitivity analysis helps us understand how demand changes in response to price adjustments. This is critical when:
    - Running A/B pricing tests
    - Designing promotions or discounts
    - Exploring dynamic pricing strategies

    Even without a price history table, we can approximate patterns using the current data. Products with multiple recorded price points and corresponding shifts in quantity sold can already offer valuable directional insights. We have the history prices in the orders table, but another one and the reason of why the price update will help us in many ways... liek tracking how the % change of the price impacts in the revenue...

    This kind of analysis empowers teams to make pricing decisions that balance profit margins with customer conversion.

    ### Order Frequency by Customer
    Understanding how frequently users place orders allows for customer segmentation:
    - High-frequency = loyal users
    - Low-frequency = churn risk
    - One-time buyers = opportunity for re-engagement

    This insight is more about understanding the consumer than about predicting them. While some teams might be tempted to build machine learning models to forecast the next purchase, that often doesn’t translate to direct value. What does help is understanding the overall rhythm of the customer journey — how often do they come back, and what nudges could bring them back more often?

    ### Bonus Idea: Behavioral Clustering via User Interactions
    If we integrate data from platforms like GA4 and track which categories or products users interact with the most, we can go even further. By clustering users based on their browsing and interaction behavior, we could build a personalized e-commerce experience.

    This could be done efficiently using BigQuery alone or by leveraging Vertex AI to serve a simple, custom recommender model. The goal isn’t to reinvent the wheel — just to use our data to meet each customer where they are, with the products they already care about.
    
2. What ETL/ELT tool would you use to extract this data and insert it into BigQuery? Explain the steps of creating this type of pipeline

    ### ETL/ELT Pipeline Design for BigQuery
    My Approach (Already in Production)
    The solution I built for our Brazilian e-commerce platform is not just theoretical — it's already running in production and supports integrations with platforms like MercadoLibre, Puma.com, and other marketplace aggregators.

    Our architecture looks like this:

    Incoming Orders via API Gateway (Apigee)
    These platforms send order requests to Apigee, which acts as our gateway.

    Event-Driven Cloud Storage Buckets
    Each order request is written to a Cloud Storage bucket with a 30-day retention policy.

    Trigger to Cloud Run (in Go)
    Every time a new file arrives, a Cloud Run service (written in Golang for performance) is triggered. This service:

    Inserts the order into Spanner

    Creates the order in our custom-built OMS (Order Management System)

    Synchronizes stock levels across all external systems

    Writes a cleaned and transformed version of the order back to Cloud Storage

    BigQuery Ingestion:
    Later, this structured and OMS-compatible data is loaded into BigQuery, enabling real-time sales performance analysis.

    While this design may “break the rules” of the test by zubale, it reflects a very pragmatic and scalable solution tailored to a complex environment with many moving parts. In this case, I wasn’t just creating an ETL — I was also building features typically expected from an OMS, due to unique business constraints.

    Scalable Alternative for Big Data: Dataflow
    In a more traditional or massive-scale scenario — where millions of orders are stored as files, arriving unpredictably in Cloud Storage — a different approach might be preferable.

    Why Dataflow?
    - Built for streaming and batch data processing
    - Fully managed and auto-scalable
    - Offers tight integration with BigQuery (via Storage API or load jobs)
    - Better long-term support compared to Dataproc/Spark, which Google no longer recommends for most use cases

    Suggested Tech Stack:
    Cloud Storage: Ingests raw order data files (e.g. JSON, CSV, Avro)

    Dataflow (Golang SDK preferred): Parses, transforms, and enriches the data

    BigQuery: Serves as the analytical destination for reporting and real-time insights

    Golang is preferred here for performance and efficiency, especially in compute-heavy transformations — though Python could be acceptable for simpler workloads.

    Why Not Dataproc or Spark?
    While Dataproc with Apache Spark was once the go-to solution for big data processing, it's no longer the recommended path for most Google Cloud architectures. Dataflow is more modern, serverless, and better aligned with the GCP ecosystem's direction.

3. What AI-based pipeline could you add to this pipeline? Describe it. 

    ### Predictive Delivery Date Estimation

    Objective:  
    Build a machine learning model to accurately estimate the delivery date of an order based on various real-world factors.

    Why it's useful:  
    One of the biggest frustrations for customers in e-commerce is delivery uncertainty. Offering a reliable, AI-driven estimated delivery date at checkout improves customer trust and satisfaction, and helps reduce support tickets.

    How it works:  
    We would train a regression model using historical delivery data. The input features could include:
    - Customer location (zip code, city)
    - Warehouse location
    - Day of the week and time of order
    - Product type (bulky, standard, express)
    - Weather conditions (if available)
    - Carrier performance metrics (if available)
    - Public holidays

    ### Real-Time Sales Anomaly Detection

    Objective:  
    Train a model to detect whether current sales performance is below or above expected levels for a given day, triggering alerts automatically.

    Why it's useful:  
    This system would act as a real-time safety net for the business. A sudden drop in sales could indicate a problem with our payment systems, stock synchronization, or site availability. On the other hand, an unexpected spike in orders might signal an issue with pricing logic or unintentional discounts.

    How it works:  
    - Use historical order data (e.g., number of orders, revenue, conversion rate) to train a time-series forecasting model or a supervised anomaly detector.
    - Input features might include:
    - Day of the week, seasonality, holidays
    - Campaign activity (if tracked)
    - Product categories sold
    - When real-time sales data diverges significantly from expected values, trigger automated alerts via email, Slack, or monitoring dashboards.

    Tools:  
    - Vertex AI or BigQuery ML for modeling  
    - Integration with Pub/Sub, Cloud Functions or custom alerting tools for notification