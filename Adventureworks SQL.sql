CREATE DATABASE AdventureWorksDW;
USE AdventureWorksDW;

CREATE TABLE DimCustomer (
    CustomerKey INT PRIMARY KEY,
	GeographyKey INT,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Gender VARCHAR(10),
    EmailAddress VARCHAR(100),
    YearlyIncome DECIMAL(12,2)
);
select* from dimcustomer;
select count(*) from dimcustomer;

CREATE TABLE DimProductCategory (
    ProductCategoryKey INT PRIMARY KEY,
    CategoryName VARCHAR(100)
);

CREATE TABLE DimProductSubCategory (
    ProductSubCategoryKey INT PRIMARY KEY,
     SubCategoryName VARCHAR(100),
    ProductCategoryKey INT,
    FOREIGN KEY (ProductCategoryKey) REFERENCES DimProductCategory(ProductCategoryKey)
);

CREATE TABLE DimProduct (
    ProductKey INT PRIMARY KEY,
	UnitPrice DECIMAL(10,2),
    ProductSubCategoryKey INT,
    ProductName VARCHAR(100),
    Color VARCHAR(50),
    Size VARCHAR(20),
    FOREIGN KEY (ProductSubCategoryKey) REFERENCES DimProductSubCategory(ProductSubCategoryKey)
);

ALTER TABLE DimProduct
ADD COLUMN StandardCost DECIMAL(10,2);


CREATE TABLE DimDate (
    OrderDateKey DATE PRIMARY KEY,
    DayNumberOfWeek INT,
    DayNameOfWeek VARCHAR(20),
    DayNumberOfMonth INT,
    DayNumberOfYear INT,
    WeekNumberOfYear INT,
    MonthName VARCHAR(20),
    MonthNumberOfYear INT,
    CalendarQuarter INT,
    CalendarYear INT,
    CalendarSemester INT,
    FiscalQuarter INT,
    FiscalYear INT,
    FiscalSemester INT
);
select * from dimdate;
SELECT COUNT(*) FROM dimdate;
drop table dimdate;


CREATE TABLE DimSalesTerritory (
    SalesTerritoryKey INT PRIMARY KEY,
    SalesTerritoryRegion VARCHAR(100),
    SalesTerritoryCountry VARCHAR(100),
    SalesTerritoryGroup VARCHAR(100)
);


CREATE TABLE FactInternetSales (
    ProductKey INT PRIMARY KEY AUTO_INCREMENT,
    CustomerKey INT,
    PromotionKey INT,
    CurrencyKey INT,
    SalesTerritoryKey INT,
    SalesOrderNumber VARCHAR(50),
    SalesOrderLineNumber INT,
    RevisionNumber INT,
    OrderQuantity INT,
    UnitPrice decimal(12,2),
    ExtendedAmount DECIMAL(12,2),
    UnitPriceDiscountPct INT,
    DiscountAmount INT,
    ProductStandardCost decimal(12,2),
    TotalProductCost decimal(12,2),
    SalesAmount decimal(12,2),
    TaxAmt decimal(12,2),
    Freight DECIMAL(12,2),
    OrderDateKey DATE,
    DueDateKey date,
    ShipDateKey date,
    FOREIGN KEY (CustomerKey) REFERENCES DimCustomer(CustomerKey),
    FOREIGN KEY (ProductKey) REFERENCES DimProduct(ProductKey),
    FOREIGN KEY (OrderDateKey) REFERENCES DimDate(OrderDateKey),
    FOREIGN KEY (SalesTerritoryKey) REFERENCES DimSalesTerritory(SalesTerritoryKey)
);

CREATE TABLE Fact_Internet_Sales_New (
    ProductKey INT PRIMARY KEY AUTO_INCREMENT,
    CustomerKey INT,
    PromotionKey INT,
    CurrencyKey INT,
    SalesTerritoryKey INT,
    SalesOrderNumber VARCHAR(50),
    SalesOrderLineNumber INT,
    RevisionNumber INT,
    OrderQuantity INT,
    UnitPrice decimal(12,2),
    ExtendedAmount DECIMAL(12,2),
    UnitPriceDiscountPct INT,
    DiscountAmount INT,
    ProductStandardCost decimal(12,2),
    TotalProductCost decimal(12,2),
    SalesAmount decimal(12,2),
    TaxAmt decimal(12,2),
    Freight DECIMAL(12,2),
    OrderDateKey DATE,
    DueDateKey date,
    ShipDateKey date,
    FOREIGN KEY (CustomerKey) REFERENCES DimCustomer(CustomerKey),
    FOREIGN KEY (ProductKey) REFERENCES DimProduct(ProductKey),
    FOREIGN KEY (OrderDateKey) REFERENCES DimDate(OrderDateKey),
    FOREIGN KEY (SalesTerritoryKey) REFERENCES DimSalesTerritory(SalesTerritoryKey)
);


-- 0. Union of Fact Internet sales and Fact internet sales new
select * from factinternetsales
union all
select * from fact_internet_sales_new;

-- 1.Lookup the productname from the Product sheet to Sales sheet.
SELECT 
    f.SalesOrderNumber,
    f.ProductKey,
    p.ProductName AS ProductName,
    f.OrderQuantity,
    f.UnitPrice
FROM FactInternetSales f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey;
    
    
-- 2.Lookup the Customerfullname from the Customer and Unit Price from Product sheet to Sales sheet.
SELECT 
    s. SalesOrderNumber,
    c.CustomerKey,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerFullName,
    p.ProductKey,
    p.ProductName,
    p.UnitPrice,
    s.OrderQuantity
FROM FactInternetSales s
JOIN DimCustomer c 
    ON s.CustomerKey = c.CustomerKey
JOIN DimProduct p 
    ON s.ProductKey = p.ProductKey;

-- 3.calcuate the following fields from the Orderdatekey field ( First Create a Date Field from Orderdatekey)
--    A.Year

SELECT YEAR(OrderDateKey) AS Year
FROM FactInternetSales;

--    B.Monthno
SELECT MONTH(OrderDateKey) AS MonthNo
FROM FactInternetSales;

--    C.Monthfullname
SELECT MONTHNAME(OrderDateKey) AS MonthFullName
FROM FactInternetSales;

-- D. Quarter (Q1, Q2, Q3, Q4)
SELECT CONCAT('Q', QUARTER(OrderDateKey)) AS Quarter
FROM FactInternetSales;

-- E. YearMonth (YYYY-MMM)
SELECT DATE_FORMAT(OrderDateKey, '%Y-%b') AS YearMonth
FROM FactInternetSales;

  -- F. Weekdayno
SELECT DAYOFWEEK(OrderDateKey) AS WeekdayNo
FROM FactInternetSales;

-- G. Weekday Name
SELECT DAYNAME(OrderDateKey) AS WeekdayName
FROM FactInternetSales;

-- H. Financial Month
SELECT 
   CASE 
      WHEN MONTH(OrderDateKey) >= 4 THEN MONTH(OrderDateKey) - 3
      ELSE MONTH(OrderDateKey) + 9
   END AS FinancialMonth
FROM FactInternetSales;

-- I. Financial Quarter
SELECT 
   CASE 
      WHEN MONTH(OrderDateKey) BETWEEN 4 AND 6 THEN 'Q1'
      WHEN MONTH(OrderDateKey) BETWEEN 7 AND 9 THEN 'Q2'
      WHEN MONTH(OrderDateKey) BETWEEN 10 AND 12 THEN 'Q3'
      ELSE 'Q4'
   END AS FinancialQuarter
FROM FactInternetSales;

-- 4.Calculate the Sales amount uning the columns(unit price,order quantity,unit discount)
SELECT 
    (UnitPrice * OrderQuantity - DiscountAmount) AS SalesAmount
FROM FactInternetSales;

-- 5.Calculate the Productioncost uning the columns(unit cost ,order quantity)

SELECT 
    (p.StandardCost * s.OrderQuantity) AS ProductionCost
FROM FactInternetSales s
JOIN DimProduct p  
    ON s.ProductKey = p.ProductKey;

-- 6.Calculate the profit.
SELECT 
    (s.UnitPrice * s.OrderQuantity * (1 - s.UnitPriceDiscountPct)) AS SalesAmount,
    (p.StandardCost * s.OrderQuantity) AS ProductionCost,
    ((s.UnitPrice * s.OrderQuantity * (1 - s.UnitPriceDiscountPct)) - (p.StandardCost * s.OrderQuantity)) AS Profit
FROM FactInternetSales s
JOIN DimProduct p 
    ON s.ProductKey = p.ProductKey;

-- 7.Create a Pivot table for month and sales (provide the Year as filter to select a particular Year)
SELECT 
    YEAR(OrderDateKey) AS Year,
    MONTH(OrderDateKey) AS MonthNo,
    MONTHNAME(OrderDateKey) AS MonthName,
    SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM FactInternetSales
GROUP BY YEAR(OrderDateKey), MONTH(OrderDateKey), MONTHNAME(OrderDateKey)
ORDER BY Year, MonthNo;
-- 8.Create a Bar chart to show yearwise Sales
SELECT 
    YEAR(OrderDateKey) AS Year,
    SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM FactInternetSales
GROUP BY YEAR(OrderDateKey)
ORDER BY Year;

-- 9. show Monthwise sales
SELECT 
    DATE_FORMAT(OrderDateKey, '%Y-%m') AS YearMonth,
    SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM FactInternetSales
GROUP BY YearMonth
ORDER BY YearMonth;

-- 10. show Quarterwise sales
SELECT 
    CONCAT(YEAR(OrderDateKey), '-Q', QUARTER(OrderDateKey)) AS YearQuarter,
    SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM FactInternetSales
GROUP BY YearQuarter
ORDER BY YearQuarter;


  -- 11. to show Salesamount and Productioncost together

SELECT 
    YEAR(OrderDateKey) AS Year,
    SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS SalesAmount,
    SUM(UnitPrice * OrderQuantity) AS ProductionCost
FROM FactInternetSales
GROUP BY Year
ORDER BY Year;

-- 12.Build addtional KPI /Charts for Performance by Products, Customers, Region
        -- 1. Total Sales Amount
        SELECT SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM FactInternetSales;

      -- 2. Total Orders
      SELECT COUNT(DISTINCT SalesOrderNumber) AS TotalOrders
FROM FactInternetSales;

       -- 3.Top Product by Sales
SELECT p.ProductName,
       SUM(s.UnitPrice * s.OrderQuantity * (1 - s.UnitPriceDiscountPct)) AS SalesAmount
FROM FactInternetSales s
JOIN DimProduct p ON s.ProductKey = p.ProductKey
GROUP BY p.ProductName
ORDER BY SalesAmount DESC
LIMIT 5;

-- 4.Top Customer by Sales
SELECT CONCAT(c.FirstName, ' ', c.LastName) AS CustomerFullName,
       SUM(s.UnitPrice * s.OrderQuantity * (1 - s.UnitPriceDiscountPct)) AS SalesAmount
FROM FactInternetSales s
JOIN DimCustomer c ON s.CustomerKey = c.CustomerKey
GROUP BY CustomerFullName
ORDER BY SalesAmount DESC
LIMIT 5;

   -- 5.Region-wise Sales
SELECT 
    t.SalesTerritoryRegion AS Region,
    SUM(s.UnitPrice * s.OrderQuantity * (1 - s.UnitPriceDiscountPct)) AS SalesAmount
FROM FactInternetSales s
JOIN DimCustomer c 
    ON s.CustomerKey = c.CustomerKey
JOIN DimSalesTerritory t
    ON t.SalesTerritoryKey = t.SalesTerritoryKey
GROUP BY t.SalesTerritoryRegion
ORDER BY SalesAmount DESC;




SHOW COLUMNS FROM DimCustomer;

SELECT SUM(SalesAmount) AS TotalSales FROM FactInternetSales;


SELECT COUNT(*) FROM DimCustomer;
SELECT COUNT(*) FROM DimProduct;
SELECT COUNT(*) FROM DimProductCategory;
SELECT COUNT(*) FROM DimProductSubCategory;
SELECT COUNT(*) FROM Fact_Internet_Sales_New;
SELECT COUNT(*) FROM Fact_Internet_Sales_New;

select * from DimCustomer;
select * from Fact_Internet_Sales_New;
drop table FactInternetSales;


SELECT COUNT(*) FROM Fact_Internet_Sales_New;
SELECT * FROM Fact_Internet_Sales_New LIMIT 10;



SELECT CONCAT('Q', QUARTER(OrderDateKey)) AS Quarter
FROM FactInternetSales;


