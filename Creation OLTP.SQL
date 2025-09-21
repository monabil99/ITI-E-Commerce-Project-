CREATE DATABASE E_Commerce;
GO
USE E_Commerce;
GO
CREATE SCHEMA users;
GO
CREATE SCHEMA products;
GO
CREATE SCHEMA cart;
GO
CREATE SCHEMA orders;
GO

CREATE TABLE users.Customer (
    Cust_ID INT PRIMARY KEY IDENTITY(1,1),
    Cust_Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    Address NVARCHAR(200),
    Phone NVARCHAR(20) UNIQUE,
    Registration_Date DATE DEFAULT GETDATE(),
    Password NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE products.Category (
    Category_ID INT PRIMARY KEY IDENTITY(1,1),
    Category_Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(200)
);

CREATE TABLE products.Brand (
    Brand_ID INT PRIMARY KEY IDENTITY(1,1),
    Brand_Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(200)
);

CREATE TABLE products.SubCategory (
    SubCat_ID INT PRIMARY KEY IDENTITY(1,1),
    SubCat_Name NVARCHAR(100) NOT NULL,
    Category_ID INT NOT NULL,
    CONSTRAINT FK_SubCategory_Category FOREIGN KEY (Category_ID)
        REFERENCES products.Category(Category_ID)
);

CREATE TABLE products.Product (
    Product_ID INT PRIMARY KEY IDENTITY(1,1),
    Product_Name NVARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) CHECK (Price >= 0),
    Description NVARCHAR(200),
    Stock_Quantity INT CHECK (Stock_Quantity >= 0),
    Brand_ID INT,
    SubCat_ID INT,
    FOREIGN KEY (Brand_ID) REFERENCES products.Brand(Brand_ID),
    FOREIGN KEY (SubCat_ID) REFERENCES products.SubCategory(SubCat_ID)
);
GO
CREATE TABLE orders.ShipMethod (
    ShipMethod_ID INT PRIMARY KEY IDENTITY(1,1),
    Method_Name NVARCHAR(100) NOT NULL,
    Estimated_Days INT CHECK (Estimated_Days > 0),
    Cost DECIMAL(10,2) CHECK (Cost >= 0)
);

CREATE TABLE orders.Orders (
    Order_ID INT PRIMARY KEY IDENTITY(1,1),
    Cust_ID INT NOT NULL,
    ShipMethod_ID INT NOT NULL,
    Order_Date DATETIME DEFAULT GETDATE(),
    Ship_Date DATETIME,
    Due_Date DATETIME,
    Status NVARCHAR(50) CHECK (Status IN ('Pending', 'Shipped', 'Delivered', 'Cancelled', 'Returned')),
    Total_Amount DECIMAL(10,2) NOT NULL,
    Shipping_Address NVARCHAR(255) NOT NULL,
    FOREIGN KEY (Cust_ID) REFERENCES users.Customer(Cust_ID),
    FOREIGN KEY (ShipMethod_ID) REFERENCES orders.ShipMethod(ShipMethod_ID)
);

CREATE TABLE orders.OrderDetails (
    OrderDetail_ID INT PRIMARY KEY IDENTITY(1,1),
    Quantity INT CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) CHECK (UnitPrice >= 0),
    Order_ID INT NOT NULL,
    Product_ID INT NOT NULL,
    FOREIGN KEY (Order_ID) REFERENCES orders.Orders(Order_ID),
    FOREIGN KEY (Product_ID) REFERENCES products.Product(Product_ID)
);

CREATE TABLE orders.Returned (
    Return_ID INT PRIMARY KEY IDENTITY(1,1),
    Order_ID INT NOT NULL,
    Product_ID INT NOT NULL,
    Reason NVARCHAR(500),
    Status NVARCHAR(50) NOT NULL CHECK (Status IN ('Requested', 'Approved', 'Rejected', 'Processed')),
    Requested_At DATETIME DEFAULT GETDATE(),
    Processed_At DATETIME,
    FOREIGN KEY (Order_ID) REFERENCES orders.Orders(Order_ID),
    FOREIGN KEY (Product_ID) REFERENCES products.Product(Product_ID)
);

CREATE TABLE orders.Payment (
    Payment_ID INT PRIMARY KEY IDENTITY(1,1),
    Order_ID INT NOT NULL,
    Payment_Date DATETIME DEFAULT GETDATE(),
    Payment_Method NVARCHAR(50) NOT NULL CHECK (Payment_Method IN ('Credit Card', 'Debit Card', 'PayPal', 'Cash on Delivery', 'Bank Transfer')),
    Payment_Status NVARCHAR(50) NOT NULL CHECK (Payment_Status IN ('Pending', 'Completed', 'Failed', 'Refunded')),
    Amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (Order_ID) REFERENCES orders.Orders(Order_ID)
);
GO
CREATE TABLE users.Review (
    Review_ID INT PRIMARY KEY IDENTITY(1,1),
    Review_Date DATE DEFAULT GETDATE(),
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(300),
    Cust_ID INT,
    Product_ID INT,
    Order_ID INT NULL,
    FOREIGN KEY (Cust_ID) REFERENCES users.Customer(Cust_ID),
    FOREIGN KEY (Product_ID) REFERENCES products.Product(Product_ID),
    FOREIGN KEY (Order_ID) REFERENCES orders.Orders(Order_ID)
);
GO
CREATE TABLE cart.Cart (
    Cart_ID INT PRIMARY KEY IDENTITY(1,1),
    Created_At DATE DEFAULT GETDATE(),
    Cust_ID INT NOT NULL,
    FOREIGN KEY (Cust_ID) REFERENCES users.Customer(Cust_ID)
);

CREATE TABLE cart.Cart_Items (
    Cart_ID INT,
    Product_ID INT,
    Quantity INT CHECK (Quantity > 0),
    PRIMARY KEY (Cart_ID, Product_ID),
    FOREIGN KEY (Cart_ID) REFERENCES cart.Cart(Cart_ID),
    FOREIGN KEY (Product_ID) REFERENCES products.Product(Product_ID)
);

CREATE TABLE cart.Cart_Order (
    Cart_ID INT,
    Order_ID INT,
    PRIMARY KEY (Cart_ID, Order_ID),
    FOREIGN KEY (Cart_ID) REFERENCES cart.Cart(Cart_ID),
    FOREIGN KEY (Order_ID) REFERENCES orders.Orders(Order_ID)
);
GO
