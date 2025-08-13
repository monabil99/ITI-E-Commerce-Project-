CREATE DATABASE e_commerce_DWH;
GO

USE e_commerce_DWH;
GO


CREATE SCHEMA DWH;
GO


CREATE TABLE DWH.DimDate (
    DateSK INT PRIMARY KEY,
    OrderDate DATE,
    Year INT,
    Quarter INT,
    Month INT,
    Day INT,
    WeekdayName NVARCHAR(20)
);

CREATE TABLE DWH.DimCustomer (
    CustomerSK INT IDENTITY(1,1) PRIMARY KEY,
    Cust_ID INT,
    Cust_Name NVARCHAR(100),
    Email NVARCHAR(100),
    Country NVARCHAR(200),
    Phone NVARCHAR(20),
    Registration_Date DATE,
    IsCurrent BIT,
    StartDate DATE,
    EndDate DATE
);

CREATE TABLE DWH.DimProduct (
    ProductSK INT IDENTITY(1,1) PRIMARY KEY,
    Product_ID INT,
    Product_Name NVARCHAR(100),
    Price DECIMAL(10,2),
    Brand_Name NVARCHAR(100),
    SubCat_Name NVARCHAR(100),
    Category_Name NVARCHAR(100),
    IsCurrent BIT,
    StartDate DATE,
    EndDate DATE
);

CREATE TABLE DWH.DimShipMethod (
    ShipMethodSK INT IDENTITY(1,1) PRIMARY KEY,
    ShipMethod_ID INT,
    Method_Name NVARCHAR(100),
    Estimated_Days INT,
    Cost DECIMAL(10,2)
);


CREATE TABLE DWH.FactSales (
    SalesSK INT IDENTITY(1,1) PRIMARY KEY,
    Order_ID INT,
    ProductSK INT,
    CustomerSK INT,
    ShipMethodSK INT,
    OrderDateSK INT,
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    Total_Amount AS (Quantity * UnitPrice) PERSISTED,
    FOREIGN KEY (ProductSK) REFERENCES DWH.DimProduct(ProductSK),
    FOREIGN KEY (CustomerSK) REFERENCES DWH.DimCustomer(CustomerSK),
    FOREIGN KEY (ShipMethodSK) REFERENCES DWH.DimShipMethod(ShipMethodSK),
    FOREIGN KEY (OrderDateSK) REFERENCES DWH.DimDate(DateSK)
);

CREATE TABLE DWH.FactPayment (
    PaymentSK INT IDENTITY(1,1) PRIMARY KEY,
    Order_ID INT,
    Payment_DateSK INT,
    Payment_Method NVARCHAR(50),
    Payment_Status NVARCHAR(50),
    Amount DECIMAL(10,2),
    FOREIGN KEY (Payment_DateSK) REFERENCES DWH.DimDate(DateSK)
);

CREATE TABLE DWH.FactReturn (
    ReturnSK INT IDENTITY(1,1) PRIMARY KEY,
    Return_ID INT,
    Order_ID INT,
    ProductSK INT,
    Status NVARCHAR(50),
    RequestedAtSK INT,
    ProcessedAtSK INT,
    Reason NVARCHAR(500),
    FOREIGN KEY (ProductSK) REFERENCES DWH.DimProduct(ProductSK),
    FOREIGN KEY (RequestedAtSK) REFERENCES DWH.DimDate(DateSK),
    FOREIGN KEY (ProcessedAtSK) REFERENCES DWH.DimDate(DateSK)
);

CREATE TABLE DWH.FactCartActivity (
    CartSK INT IDENTITY(1,1) PRIMARY KEY,
    Cart_ID INT,
    CustomerSK INT,
    ProductSK INT,
    DateSK INT,
    Quantity INT,
    FOREIGN KEY (CustomerSK) REFERENCES DWH.DimCustomer(CustomerSK),
    FOREIGN KEY (ProductSK) REFERENCES DWH.DimProduct(ProductSK),
    FOREIGN KEY (DateSK) REFERENCES DWH.DimDate(DateSK)
);

CREATE TABLE DWH.FactReview (
    Review_ID_SK INT IDENTITY(1,1) PRIMARY KEY,
    Review_ID INT,
    CustomerSK INT,
    ProductSK INT,
    Order_ID INT,
    Rating INT,
    Comment NVARCHAR(300),
    ReviewDateSK INT,
    FOREIGN KEY (CustomerSK) REFERENCES DWH.DimCustomer(CustomerSK),
    FOREIGN KEY (ProductSK) REFERENCES DWH.DimProduct(ProductSK),
    FOREIGN KEY (ReviewDateSK) REFERENCES DWH.DimDate(DateSK)
);