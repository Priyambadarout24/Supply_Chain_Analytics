--============================================================
--SUPPLY CHAIN ANALYTICS — PHASE 1: DATA STAGING & LOAD
--============================================================

------------------------------------------------------------------------------
-- 0. DATABASE
------------------------------------------------------------------------------

IF DB_ID('SUPPLY_CHAIN_Project') IS NULL
BEGIN
    CREATE DATABASE SUPPLY_CHAIN_Project;
END

USE SUPPLY_CHAIN_Project;

------------------------------------------------------------------------------
-- 1. STAGING SCHEMA (all columns VARCHAR — raw, unvalidated load)
------------------------------------------------------------------------------
IF SCHEMA_ID('staging') IS NULL
    EXEC('CREATE SCHEMA staging');


DROP TABLE IF EXISTS staging.stg_dim_date;
DROP TABLE IF EXISTS staging.stg_Product_master;
DROP TABLE IF EXISTS staging.stg_Supplier_master;
DROP TABLE IF EXISTS staging.stg_Warehouse_master;
DROP TABLE IF EXISTS staging.stg_Sales_master;
DROP TABLE IF EXISTS staging.stg_Delivery_master;
DROP TABLE IF EXISTS staging.stg_Inventory_master;
DROP TABLE IF EXISTS staging.stg_Inventory_Ageing;
DROP TABLE IF EXISTS staging.stg_Purchase_Orders;
DROP TABLE IF EXISTS staging.stg_Warehouse_Productivity;

CREATE TABLE staging.stg_dim_date
(
    Date_Value      DATE,
    Date_Key        INT,
    Year_Value      INT,
    Month_Value     INT,
    Month_Name      VARCHAR(20),
    Quarter_Value   INT,
    Day_Name        VARCHAR(20)
);

CREATE TABLE staging.stg_Product_master
(
    Product_Key             VARCHAR(50),
    Product_Name            VARCHAR(255),
    Product_Category        VARCHAR(100),
    Product_Sub_Category    VARCHAR(100),
    Brand                   VARCHAR(100),
    Product_Cost            DECIMAL(18,2),
    Selling_Price           DECIMAL(18,2),
    Launch_Date              DATE,
    Supplier_ID             VARCHAR(50),
    Product_Rating          DECIMAL(5,2),
    Product_Status          VARCHAR(50)
);

CREATE TABLE staging.stg_Supplier_master
(
    Supplier_Key        VARCHAR(50),
    Supplier_Name       VARCHAR(255),
    Contact_Person      VARCHAR(255),
    Mobile_Number       BIGINT,
    City                VARCHAR(100),
    State               VARCHAR(100),
    Country             VARCHAR(100),
    Lead_Time_Days      INT,
    Supplier_Rating     DECIMAL(5,2)
);

CREATE TABLE staging.stg_Warehouse_master
(
    Warehouse_Key   VARCHAR(50),
    Warehouse_City  VARCHAR(100),
    Region          VARCHAR(100)
);

CREATE TABLE staging.stg_Sales_master
(
    Order_ID          VARCHAR(50),
    Order_Date        DATE,
    Customer_ID       VARCHAR(50),
    Product_ID        VARCHAR(50),
    Quantity          INT,
    Unit_Price        DECIMAL(18,2),
    Discount_Amount   DECIMAL(18,2),
    Gross_Sales       DECIMAL(18,2),
    Tax_Amount        DECIMAL(18,2),
    Net_Sales         DECIMAL(18,2),
    Product_Cost      DECIMAL(18,2),
    Profit             DECIMAL(18,2),
    Payment_ID        VARCHAR(50),
    Delivery_ID       VARCHAR(50),
    Campaign_ID       VARCHAR(50),
    Order_Channel      VARCHAR(100),
    Date_Key           INT
);

CREATE TABLE staging.stg_Delivery_master
(
    Order_ID              VARCHAR(50),
    Order_Status          VARCHAR(50),
    Order_Date            DATE,
    Dispatch_Date         DATE,
    Delivery_Date         DATE,
    Cancellation_Date     DATE NULL,
    Return_Date           DATE NULL,
    Return_Reason         VARCHAR(255) NULL,
    Refund_Amount         DECIMAL(18,2),
    Delivery_ID           VARCHAR(50),
    Courier_Partner       VARCHAR(100),
    Dispatch_Date_del     DATE NULL,
    Delivery_Date_del     DATE NULL,
    Delivery_Status       VARCHAR(50),
    Delivery_Days         DECIMAL(10,2) NULL,
    Shipping_Cost         DECIMAL(18,2),
    Delivery_City         VARCHAR(100),
    Delivery_State        VARCHAR(100),
    Is_Returned           VARCHAR(10),
    Is_Cancelled          VARCHAR(10),
    OTD_Flag              VARCHAR(50)
);

CREATE TABLE staging.stg_Inventory_master
(
    Product_ID                 VARCHAR(50),
    Warehouse_ID               VARCHAR(50),
    Warehouse_City             VARCHAR(100),
    Stock_Available            INT,
    Reorder_Level              INT,
    Reorder_Qty                INT,
    Last_Stock_Update          DATE,
    Inventory_Value            DECIMAL(18,2),
    Stockout_Flag              VARCHAR(50),
    Replenishment_Score        DECIMAL(10,4),
    Avg_Daily_Sales_Velocity    DECIMAL(18,6),
    Days_Of_Cover              DECIMAL(18,2),
    Slow_Moving_Flag           VARCHAR(50)
);

CREATE TABLE staging.stg_Inventory_Ageing
(
    Product_ID          VARCHAR(50),
    Warehouse_ID        VARCHAR(50),
    Stock_Available     INT,
    Last_Stock_Update   DATE,
    Stock_In_Date       DATE,
    Age_Days            INT,
    Ageing_Bucket       VARCHAR(50),
    Data_Source         VARCHAR(50)
);

CREATE TABLE staging.stg_Purchase_Orders
(
    PO_ID                    VARCHAR(50),
    Product_ID               VARCHAR(50),
    Warehouse_ID             VARCHAR(50),
    Supplier_ID              VARCHAR(50),
    PO_Date                  DATE,
    Declared_Lead_Time_Days  INT,
    Expected_Delivery_Date   DATE,
    Actual_Delivery_Date     DATE,
    Ordered_Qty              INT,
    Received_Qty             INT,
    PO_Status                VARCHAR(50),
    Data_Source              VARCHAR(50),
    Actual_Lead_Time_Days    DECIMAL(10,2),
    On_Time_Flag             VARCHAR(50),
    In_Full_Flag             VARCHAR(50),
    OTIF_Flag                VARCHAR(50),
    Fill_Rate                DECIMAL(10,4)
);

CREATE TABLE staging.stg_Warehouse_Productivity
(
    Warehouse_ID                 VARCHAR(50),
    Week_Start                   DATE,
    Labor_Hours                  DECIMAL(18,2),
    Units_Picked                 INT,
    Orders_Processed             INT,
    Productivity_Units_Per_Hour  DECIMAL(18,2),
    Throughput_Orders_Per_Day    DECIMAL(18,2),
    Data_Source                  VARCHAR(50)
);


------------------------------------------------------------------------------
-- 2. BULK INSERT — raw load into staging
--    NOTE: files use CRLF line endings. ROWTERMINATOR is set to '0x0a' (LF)
--    on purpose — this is the more robust setting for CSVs exported on
--    Windows and avoids silent row-splitting issues. Because of this, the
--    LAST column of every row will carry a trailing CHAR(13). We strip that
--    explicitly with RTRIM(..., CHAR(13)) in every Step-3 CAST below, so it
--    never leaks into the final typed tables.
--    Update the file path below to match where you saved the CSVs.
------------------------------------------------------------------------------

BULK INSERT staging.stg_dim_date
FROM 'C:\your_path\Supply_Chain_Analytics\data\Dim_Date.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT staging.stg_Product_master
FROM 'C:\your_path\Supply_Chain_Analytics\data\Product_master.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT staging.stg_Supplier_master
FROM 'C:\your_path\Supply_Chain_Analytics\data\Supplier_master.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT staging.stg_Warehouse_master
FROM 'C:\your_path\Supply_Chain_Analytics\data\Warehouse_master.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT staging.stg_Sales_master
FROM 'C:\your_path\Supply_Chain_Analytics\data\Sales_master.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT staging.stg_Delivery_master
FROM 'C:\your_path\Supply_Chain_Analytics\data\Delivery_master.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT staging.stg_Inventory_master
FROM 'C:\your_path\Supply_Chain_Analytics\data\Inventory_master.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT staging.stg_inventory_ageing
FROM 'C:\your_path\Supply_Chain_Analytics\data\Inventory_Ageing.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT staging.stg_Purchase_Orders
FROM 'C:\your_path\Supply_Chain_Analytics\data\Purchase_Orders.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT staging.stg_Warehouse_Productivity
FROM 'C:\your_path\Supply_Chain_Analytics\data\Warehouse_Productivity.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

-- =============================================================================
-- STEP 1: DATA QUALITY VALIDATION
-- Run this immediately after loading the 10 files into SQLite/Postgres.
-- Goal: catch structural problems BEFORE writing a single KPI query.
-- Adjust table names below if yours differ from Sales_master, Delivery_master,
-- Inventory_master, Product_master, Supplier_master, Warehouse_master,
-- Dim_Date, Purchase_Orders, Warehouse_Productivity, Inventory_Ageing.
-- =============================================================================

SELECT 'stg_dim_date' AS Table_Name, COUNT(*) AS Row_Count
FROM staging.stg_dim_date

UNION ALL

SELECT 'stg_Product_master', COUNT(*)
FROM staging.stg_Product_master

UNION ALL

SELECT 'stg_Supplier_master', COUNT(*)
FROM staging.stg_Supplier_master

UNION ALL

SELECT 'stg_Warehouse_master', COUNT(*)
FROM staging.stg_Warehouse_master

UNION ALL

SELECT 'stg_Sales_master', COUNT(*)
FROM staging.stg_Sales_master

UNION ALL

SELECT 'stg_Delivery_master', COUNT(*)
FROM staging.stg_Delivery_master

UNION ALL

SELECT 'stg_Inventory_master', COUNT(*)
FROM staging.stg_Inventory_master

UNION ALL

SELECT 'stg_Inventory_Ageing', COUNT(*)
FROM staging.stg_Inventory_Ageing

UNION ALL

SELECT 'stg_Purchase_Orders', COUNT(*)
FROM staging.stg_Purchase_Orders

UNION ALL

SELECT 'stg_Warehouse_Productivity', COUNT(*)
FROM staging.stg_Warehouse_Productivity;


------------------------------------------------------------------------------
-- 3. FINAL TYPED TABLES (dbo) + CAST from staging
--    Data types below were sized against the actual min/max values verified
--    in every file.
------------------------------------------------------------------------------

-- 3.1 Date Dimension
DROP TABLE IF EXISTS dbo.dim_date;

CREATE TABLE dbo.dim_date
(
    Date_Value      DATE PRIMARY KEY,
    Date_Key        INT,
    Year_Value      INT,
    Month_Value     INT,
    Month_Name      VARCHAR(20),
    Quarter_Value   INT,
    Day_Name        VARCHAR(20)
);

INSERT INTO dbo.dim_date
SELECT
    TRY_CAST(Date_Value AS DATE),
    TRY_CAST(Date_Key AS INT),
    TRY_CAST(Year_Value AS INT),
    TRY_CAST(Month_Value AS INT),
    Month_Name,
    TRY_CAST(Quarter_Value AS INT),
    RTRIM(Day_Name)
FROM staging.stg_dim_date;

-- 3.2 Product Dimension
DROP TABLE IF EXISTS dbo.Product_master;

CREATE TABLE dbo.Product_master
(
    Product_Key          VARCHAR(20) PRIMARY KEY,
    Product_Name         VARCHAR(255),
    Product_Category     VARCHAR(100),
    Product_Sub_Category VARCHAR(100),
    Brand                VARCHAR(100),
    Product_Cost         DECIMAL(18,2),
    Selling_Price        DECIMAL(18,2),
    Launch_Date          DATE,
    Supplier_ID          VARCHAR(20),
    Product_Rating       DECIMAL(5,2),
    Product_Status       VARCHAR(20)
);

INSERT INTO dbo.Product_master
SELECT
    Product_Key,
    Product_Name,
    Product_Category,
    Product_Sub_Category,
    Brand,
    TRY_CAST(Product_Cost AS DECIMAL(18,2)),
    TRY_CAST(Selling_Price AS DECIMAL(18,2)),
    TRY_CAST(Launch_Date AS DATE),
    Supplier_ID,
    TRY_CAST(Product_Rating AS DECIMAL(5,2)),
    RTRIM(Product_Status)
FROM staging.stg_Product_master;

-- 3.3 Supplier Dimension
DROP TABLE IF EXISTS dbo.Supplier_master;

CREATE TABLE dbo.Supplier_master
(
    Supplier_Key       VARCHAR(20) PRIMARY KEY,
    Supplier_Name      VARCHAR(255),
    Contact_Person     VARCHAR(255),
    Mobile_Number      VARCHAR(20),
    City               VARCHAR(100),
    [State]            VARCHAR(100),
    Country            VARCHAR(100),
    Lead_Time_Days     INT,
    Supplier_Rating    DECIMAL(5,2)
);

INSERT INTO dbo.Supplier_master
SELECT
    Supplier_Key,
    Supplier_Name,
    Contact_Person,
    Mobile_Number,
    City,
    [State],
    Country,
    TRY_CAST(Lead_Time_Days AS INT),
    TRY_CAST(Supplier_Rating AS DECIMAL(5,2))
FROM staging.stg_Supplier_master;

-- 3.4 Warehouse Dimension
DROP TABLE IF EXISTS dbo.Warehouse_master;

CREATE TABLE dbo.Warehouse_master
(
    Warehouse_Key   VARCHAR(20) PRIMARY KEY,
    Warehouse_City  VARCHAR(100),
    Region          VARCHAR(100)
);

INSERT INTO dbo.Warehouse_master
SELECT
    Warehouse_Key,
    Warehouse_City,
    RTRIM(Region)
FROM staging.stg_Warehouse_master;

-- 3.5 Sales Fact
DROP TABLE IF EXISTS dbo.Sales_master;

CREATE TABLE dbo.Sales_master
(
    Order_ID          VARCHAR(30) PRIMARY KEY,
    Order_Date        DATE,
    Customer_ID       VARCHAR(30),
    Product_ID        VARCHAR(30),
    Quantity          INT,
    Unit_Price        DECIMAL(18,2),
    Discount_Amount   DECIMAL(18,2),
    Gross_Sales       DECIMAL(18,2),
    Tax_Amount        DECIMAL(18,2),
    Net_Sales         DECIMAL(18,2),
    Product_Cost      DECIMAL(18,2),
    Profit            DECIMAL(18,2),
    Payment_ID        VARCHAR(30),
    Delivery_ID       VARCHAR(30),
    Campaign_ID       VARCHAR(30),
    Order_Channel     VARCHAR(50),
    Date_Key          INT
);

INSERT INTO dbo.Sales_master
SELECT
    Order_ID,
    TRY_CAST(Order_Date AS DATE),
    Customer_ID,
    Product_ID,
    TRY_CAST(Quantity AS INT),
    TRY_CAST(Unit_Price AS DECIMAL(18,2)),
    TRY_CAST(Discount_Amount AS DECIMAL(18,2)),
    TRY_CAST(Gross_Sales AS DECIMAL(18,2)),
    TRY_CAST(Tax_Amount AS DECIMAL(18,2)),
    TRY_CAST(Net_Sales AS DECIMAL(18,2)),
    TRY_CAST(Product_Cost AS DECIMAL(18,2)),
    TRY_CAST(Profit AS DECIMAL(18,2)),
    Payment_ID,
    Delivery_ID,
    Campaign_ID,
    RTRIM(Order_Channel),
    TRY_CAST(Date_Key AS INT)
FROM staging.stg_Sales_master;


-- 3.6 Delivery_master
DROP TABLE IF EXISTS dbo.Delivery_master;

CREATE TABLE dbo.Delivery_master
(
    Order_ID              VARCHAR(30) PRIMARY KEY,
    Order_Status          VARCHAR(50),
    Order_Date            DATE,
    Dispatch_Date         DATE,
    Delivery_Date         DATE,
    Cancellation_Date     DATE NULL,
    Return_Date           DATE NULL,
    Return_Reason         VARCHAR(255) NULL,
    Refund_Amount         DECIMAL(18,2),
    Delivery_ID           VARCHAR(30),
    Courier_Partner       VARCHAR(100),
    Dispatch_Date_del     DATE NULL,
    Delivery_Date_del     DATE NULL,
    Delivery_Status       VARCHAR(50),
    Delivery_Days         DECIMAL(10,2),
    Shipping_Cost         DECIMAL(18,2),
    Delivery_City         VARCHAR(100),
    Delivery_State        VARCHAR(100),
    Is_Returned           VARCHAR(10),
    Is_Cancelled          VARCHAR(10),
    OTD_Flag              VARCHAR(50)
);

INSERT INTO dbo.Delivery_master
SELECT
    Order_ID,
    Order_Status,
    TRY_CAST(Order_Date AS DATE),
    TRY_CAST(Dispatch_Date AS DATE),
    TRY_CAST(Delivery_Date AS DATE),
    TRY_CAST(NULLIF(Cancellation_Date,'') AS DATE),
    TRY_CAST(NULLIF(Return_Date,'') AS DATE),
    NULLIF(Return_Reason,''),
    TRY_CAST(Refund_Amount AS DECIMAL(18,2)),
    Delivery_ID,
    Courier_Partner,
    TRY_CAST(Dispatch_Date_del AS DATE),
    TRY_CAST(Delivery_Date_del AS DATE),
    Delivery_Status,
    TRY_CAST(Delivery_Days AS DECIMAL(10,2)),
    TRY_CAST(Shipping_Cost AS DECIMAL(18,2)),
    Delivery_City,
    Delivery_State,
    Is_Returned,
    Is_Cancelled,
    OTD_Flag
FROM staging.stg_Delivery_master;

-- 3.7 Inventory_master
DROP TABLE IF EXISTS dbo.Inventory_master;

CREATE TABLE dbo.Inventory_master
(
    Product_ID                  VARCHAR(30),
    Warehouse_ID                VARCHAR(30),
    Warehouse_City              VARCHAR(100),
    Stock_Available             INT,
    Reorder_Level               INT,
    Reorder_Qty                 INT,
    Last_Stock_Update           DATE,
    Inventory_Value             DECIMAL(18,2),
    Stockout_Flag               VARCHAR(30),
    Replenishment_Score         DECIMAL(18,4),
    Avg_Daily_Sales_Velocity    DECIMAL(18,8),
    Days_Of_Cover               DECIMAL(18,2),
    Slow_Moving_Flag            VARCHAR(30)
);

INSERT INTO dbo.Inventory_master
SELECT
    Product_ID,
    Warehouse_ID,
    Warehouse_City,

    TRY_CAST(Stock_Available AS INT),
    TRY_CAST(Reorder_Level AS INT),
    TRY_CAST(Reorder_Qty AS INT),

    TRY_CAST(Last_Stock_Update AS DATE),

    TRY_CAST(Inventory_Value AS DECIMAL(18,2)),

    RTRIM(Stockout_Flag),

    TRY_CAST(Replenishment_Score AS DECIMAL(18,4)),
    TRY_CAST(Avg_Daily_Sales_Velocity AS DECIMAL(18,8)),
    TRY_CAST(Days_Of_Cover AS DECIMAL(18,2)),

    RTRIM(Slow_Moving_Flag)

FROM staging.stg_Inventory_master;

-- 3.8 Inventory_Ageing
DROP TABLE IF EXISTS dbo.Inventory_Ageing;

CREATE TABLE dbo.Inventory_Ageing
(
    Product_ID          VARCHAR(30),
    Warehouse_ID        VARCHAR(30),
    Stock_Available     INT,
    Last_Stock_Update   DATE,
    Stock_In_Date       DATE,
    Age_Days            INT,
    Ageing_Bucket       VARCHAR(30),
    Data_Source         VARCHAR(30)
);

INSERT INTO dbo.Inventory_Ageing
SELECT
    Product_ID,
    Warehouse_ID,

    TRY_CAST(Stock_Available AS INT),

    TRY_CAST(Last_Stock_Update AS DATE),
    TRY_CAST(Stock_In_Date AS DATE),

    TRY_CAST(Age_Days AS INT),

    RTRIM(Ageing_Bucket),
    RTRIM(Data_Source)

FROM staging.stg_Inventory_Ageing;

-- 3.9 Purchase_Orders
DROP TABLE IF EXISTS dbo.Purchase_Orders;

CREATE TABLE dbo.Purchase_Orders
(
    PO_ID                    VARCHAR(30) PRIMARY KEY,
    Product_ID               VARCHAR(30),
    Warehouse_ID             VARCHAR(30),
    Supplier_ID              VARCHAR(30),
    PO_Date                  DATE,
    Declared_Lead_Time_Days  INT,
    Expected_Delivery_Date   DATE,
    Actual_Delivery_Date     DATE,
    Ordered_Qty              INT,
    Received_Qty             INT,
    PO_Status                VARCHAR(50),
    Data_Source              VARCHAR(50),
    Actual_Lead_Time_Days    DECIMAL(10,2),
    On_Time_Flag             VARCHAR(30),
    In_Full_Flag             VARCHAR(30),
    OTIF_Flag                VARCHAR(30),
    Fill_Rate                DECIMAL(10,4)
);

INSERT INTO dbo.Purchase_Orders
SELECT
    PO_ID,
    Product_ID,
    Warehouse_ID,
    Supplier_ID,

    TRY_CAST(PO_Date AS DATE),

    TRY_CAST(Declared_Lead_Time_Days AS INT),

    TRY_CAST(Expected_Delivery_Date AS DATE),
    TRY_CAST(Actual_Delivery_Date AS DATE),

    TRY_CAST(Ordered_Qty AS INT),
    TRY_CAST(Received_Qty AS INT),

    RTRIM(PO_Status),
    RTRIM(Data_Source),

    TRY_CAST(Actual_Lead_Time_Days AS DECIMAL(10,2)),

    RTRIM(On_Time_Flag),
    RTRIM(In_Full_Flag),
    RTRIM(OTIF_Flag),

    TRY_CAST(Fill_Rate AS DECIMAL(10,4))

FROM staging.stg_Purchase_Orders;

-- 3.10 Warehouse_Productivity
DROP TABLE IF EXISTS dbo.Warehouse_Productivity;

CREATE TABLE dbo.Warehouse_Productivity
(
    Warehouse_ID                VARCHAR(30),
    Week_Start                  DATE,
    Labor_Hours                 DECIMAL(18,2),
    Units_Picked                INT,
    Orders_Processed            INT,
    Productivity_Units_Per_Hour DECIMAL(18,2),
    Throughput_Orders_Per_Day   DECIMAL(18,2),
    Data_Source                 VARCHAR(50)
);

INSERT INTO dbo.Warehouse_Productivity
SELECT
    Warehouse_ID,

    TRY_CAST(Week_Start AS DATE),

    TRY_CAST(Labor_Hours AS DECIMAL(18,2)),
    TRY_CAST(Units_Picked AS INT),
    TRY_CAST(Orders_Processed AS INT),

    TRY_CAST(Productivity_Units_Per_Hour AS DECIMAL(18,2)),
    TRY_CAST(Throughput_Orders_Per_Day AS DECIMAL(18,2)),

    RTRIM(Data_Source)

FROM staging.stg_Warehouse_Productivity;


-- 1. ROW COUNTS — sanity check against expected volumes
SELECT 'Sales_master' AS table_name, COUNT(*) AS row_count FROM Sales_master
UNION ALL SELECT 'Delivery_master', COUNT(*) FROM Delivery_master
UNION ALL SELECT 'Inventory_master', COUNT(*) FROM Inventory_master
UNION ALL SELECT 'Product_master', COUNT(*) FROM Product_master
UNION ALL SELECT 'Supplier_master', COUNT(*) FROM Supplier_master
UNION ALL SELECT 'Warehouse_master', COUNT(*) FROM Warehouse_master
UNION ALL SELECT 'Dim_Date', COUNT(*) FROM Dim_Date
UNION ALL SELECT 'Purchase_Orders', COUNT(*) FROM Purchase_Orders
UNION ALL SELECT 'Warehouse_Productivity', COUNT(*) FROM Warehouse_Productivity
UNION ALL SELECT 'Inventory_Ageing', COUNT(*) FROM Inventory_Ageing;

-- 2. DUPLICATE PRIMARY KEYS — should return zero rows for each
SELECT Product_Key, COUNT(*) AS c FROM Product_master GROUP BY Product_Key HAVING COUNT(*) > 1;
SELECT Supplier_Key, COUNT(*) AS c FROM Supplier_master GROUP BY Supplier_Key HAVING COUNT(*) > 1;
SELECT Order_ID, COUNT(*) AS c FROM Delivery_master GROUP BY Order_ID HAVING COUNT(*) > 1;

-- 3. ORPHAN FOREIGN KEYS — Product_IDs in Sales that don't exist in Product_master
SELECT DISTINCT s.Product_ID
FROM Sales_master s
LEFT JOIN Product_master p ON s.Product_ID = p.Product_Key
WHERE p.Product_Key IS NULL;

SELECT DISTINCT p.Supplier_ID
FROM Product_master p
LEFT JOIN Supplier_master s ON p.Supplier_ID = s.Supplier_Key
WHERE s.Supplier_Key IS NULL;
 
SELECT DISTINCT i.Warehouse_ID
FROM Inventory_master i
LEFT JOIN Warehouse_master w ON i.Warehouse_ID = w.Warehouse_Key
WHERE w.Warehouse_Key IS NULL;

-- 4. NULL CHECKS
SELECT
    SUM(CASE WHEN Stock_Available IS NULL THEN 1 ELSE 0 END) AS null_stock,
    SUM(CASE WHEN Reorder_Level IS NULL THEN 1 ELSE 0 END) AS null_reorder_level,
    SUM(CASE WHEN Inventory_Value IS NULL THEN 1 ELSE 0 END) AS null_inv_value
FROM Inventory_master;
 
SELECT
    SUM(CASE WHEN Delivery_Days IS NULL THEN 1 ELSE 0 END) AS null_delivery_days,
    SUM(CASE WHEN Shipping_Cost IS NULL THEN 1 ELSE 0 END) AS null_shipping_cost
FROM Delivery_master;
 
-- 5. DATE RANGE SANITY
-- If Order_Date imported as NVARCHAR/TEXT instead of DATE, wrap with TRY_CAST:
-- SELECT MIN(TRY_CAST(Order_Date AS DATE)), MAX(TRY_CAST(Order_Date AS DATE)) FROM Sales_master;
SELECT MIN(Order_Date) AS min_date, MAX(Order_Date) AS max_date FROM Sales_master;
SELECT MIN(PO_Date) AS min_po_date, MAX(PO_Date) AS max_po_date FROM Purchase_Orders; 

-- 6. VALUE RANGE SANITY
SELECT * FROM Sales_master WHERE Quantity <= 0 OR Unit_Price < 0;
SELECT * FROM Supplier_master WHERE Supplier_Rating < 1 OR Supplier_Rating > 5;
SELECT * FROM Inventory_master WHERE Stock_Available < 0 OR Reorder_Level < 0;

-- =============================================================================
-- STEP 2: KPI QUERIES 
-- Organized by confidence tier. Run after 01_data_quality_checks_SSMS.sql passes clean.
-- =============================================================================
 
-- ============================ DIRECT ============================
 
-- Stockout rate
SELECT
    COUNT(CASE WHEN Stock_Available <= Reorder_Level THEN 1 END) AS at_risk_skus,
    COUNT(*) AS total_skus,
    CAST(100.0 * COUNT(CASE WHEN Stock_Available <= Reorder_Level THEN 1 END) / COUNT(*) AS DECIMAL(5,1)) AS stockout_rate_pct
FROM Inventory_master;

-- Inventory value by warehouse
SELECT Warehouse_ID, CAST(SUM(Inventory_Value) AS DECIMAL(18,2)) AS total_value
FROM Inventory_master
GROUP BY Warehouse_ID
ORDER BY total_value DESC;

-- Avg delivery days + OTD vs 5-day SLA
SELECT
    CAST(AVG(CAST(Delivery_Days AS FLOAT)) AS DECIMAL(5,2)) AS avg_delivery_days,
    CAST(100.0 * SUM(CASE WHEN Delivery_Days <= 5 THEN 1 ELSE 0 END) / COUNT(Delivery_Days) AS DECIMAL(5,1)) AS otd_pct_vs_5day_sla
FROM Delivery_master
WHERE Delivery_Days IS NOT NULL;
 

-- Return rate and refund total
SELECT
    COUNT(CASE WHEN Return_Date IS NOT NULL THEN 1 END) AS returned_orders,
    COUNT(*) AS total_orders,
    CAST(100.0 * COUNT(CASE WHEN Return_Date IS NOT NULL THEN 1 END) / COUNT(*) AS DECIMAL(5,1)) AS return_rate_pct,
    CAST(SUM(Refund_Amount) AS DECIMAL(18,2)) AS total_refund_amount
FROM Delivery_master;

-- Total shipping cost
SELECT CAST(SUM(Shipping_Cost) AS DECIMAL(18,2)) AS total_shipping_cost FROM Delivery_master;
 
-- Supplier lead time & rating
SELECT Supplier_Key AS Supplier_ID, Supplier_Name, Lead_Time_Days, Supplier_Rating
FROM Supplier_master
ORDER BY Supplier_Rating DESC;

-- ========================================================
 
-- Slow-moving / excess stock: 90-day velocity vs stock, quantile-based (top 25% flagged)
WITH velocity AS (
    SELECT
        Product_ID,
        SUM(Quantity) / 90.0 AS avg_daily_velocity
    FROM Sales_master
    WHERE Order_Date >= DATEADD(DAY, -90, (SELECT MAX(Order_Date) FROM Sales_master))
    GROUP BY Product_ID
),
cover AS (
    SELECT
        i.Product_ID,
        i.Warehouse_ID,
        i.Stock_Available,
        COALESCE(v.avg_daily_velocity, 0) AS velocity,
        CASE WHEN COALESCE(v.avg_daily_velocity, 0) > 0
             THEN i.Stock_Available / v.avg_daily_velocity
             ELSE NULL END AS days_of_cover
    FROM Inventory_master i
    LEFT JOIN velocity v ON i.Product_ID = v.Product_ID
)
-- Simplest, most portable way to get the 75th percentile in SQL Server:
-- PERCENTILE_CONT (no OFFSET/subquery fragility).
SELECT DISTINCT
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_of_cover) OVER () AS p75_days_of_cover
FROM cover
WHERE days_of_cover IS NOT NULL;
-- Replenishment need score (top 20)
SELECT TOP 20
    Product_ID, Warehouse_ID,
    CAST(
        CASE WHEN Reorder_Qty > 0
             THEN (CASE WHEN (Reorder_Level - Stock_Available) > 0 THEN (Reorder_Level - Stock_Available) ELSE 0 END) * 1.0 / Reorder_Qty
             ELSE 0 END
    AS DECIMAL(5,2)) AS replenishment_score
FROM Inventory_master
ORDER BY replenishment_score DESC;

-- ========================================================
 
-- True OTIF % by supplier rating band
SELECT
    CASE
        WHEN sup.Supplier_Rating <= 3.5 THEN '<=3.5'
        WHEN sup.Supplier_Rating <= 4.0 THEN '3.5-4.0'
        WHEN sup.Supplier_Rating <= 4.5 THEN '4.0-4.5'
        ELSE '4.5-5.0'
    END AS rating_band,
    COUNT(*) AS po_count,
    CAST(100.0 * SUM(CASE WHEN po.OTIF_Flag = 'OTIF' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS otif_pct
FROM Purchase_Orders po
JOIN Supplier_master sup ON po.Supplier_ID = sup.Supplier_Key
WHERE po.PO_Status <> 'Cancelled'
GROUP BY
    CASE
        WHEN sup.Supplier_Rating <= 3.5 THEN '<=3.5'
        WHEN sup.Supplier_Rating <= 4.0 THEN '3.5-4.0'
        WHEN sup.Supplier_Rating <= 4.5 THEN '4.0-4.5'
        ELSE '4.5-5.0'
    END
ORDER BY rating_band;
 
-- Vendor fill rate by supplier (worst 20)
SELECT TOP 20
    Supplier_ID,
    CAST(AVG(Fill_Rate) * 100 AS DECIMAL(5,1)) AS avg_fill_rate_pct,
    COUNT(*) AS po_count
FROM Purchase_Orders
WHERE PO_Status <> 'Cancelled'
GROUP BY Supplier_ID
ORDER BY avg_fill_rate_pct ASC;
 
-- Actual vs declared lead time variance (top 20 by variance)
SELECT TOP 20
    po.Supplier_ID,
    sup.Lead_Time_Days AS declared_lead_time,
    CAST(AVG(po.Actual_Lead_Time_Days) AS DECIMAL(5,1)) AS actual_avg_lead_time,
    CAST(AVG(po.Actual_Lead_Time_Days) - sup.Lead_Time_Days AS DECIMAL(5,1)) AS variance_days
FROM Purchase_Orders po
JOIN Supplier_master sup ON po.Supplier_ID = sup.Supplier_Key
GROUP BY po.Supplier_ID, sup.Lead_Time_Days
ORDER BY variance_days DESC;
 
-- Warehouse productivity & throughput
SELECT
    Warehouse_ID,
    CAST(AVG(Productivity_Units_Per_Hour) AS DECIMAL(5,1)) AS avg_productivity,
    CAST(AVG(Throughput_Orders_Per_Day) AS DECIMAL(5,1)) AS avg_throughput
FROM Warehouse_Productivity
GROUP BY Warehouse_ID
ORDER BY avg_productivity DESC;
 
-- Inventory ageing distribution
SELECT Ageing_Bucket, COUNT(*) AS sku_count
FROM Inventory_Ageing
GROUP BY Ageing_Bucket
ORDER BY
    CASE Ageing_Bucket
        WHEN '0-30d' THEN 1 WHEN '31-60d' THEN 2 WHEN '61-90d' THEN 3
        WHEN '91-180d' THEN 4 ELSE 5 END;

