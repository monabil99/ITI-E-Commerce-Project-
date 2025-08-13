
-- ============================
-- Data Consistency Check Script for E_Commerce DB
-- ============================

-- ========== Orphaned Foreign Keys ==========
-- Orders without valid Customers
SELECT 'Orphan Orders (Customer)' AS Test, COUNT(*) AS Failures
FROM orders.Orders o
LEFT JOIN users.Customer c ON o.Cust_ID = c.Cust_ID
WHERE c.Cust_ID IS NULL;

-- Orders without valid Ship Methods
SELECT 'Orphan Orders (ShipMethod)', COUNT(*)
FROM orders.Orders o
LEFT JOIN orders.ShipMethod s ON o.ShipMethod_ID = s.ShipMethod_ID
WHERE s.ShipMethod_ID IS NULL;

-- OrderDetails with missing Orders
SELECT 'Orphan OrderDetails (Order)', COUNT(*)
FROM orders.OrderDetails od
LEFT JOIN orders.Orders o ON od.Order_ID = o.Order_ID
WHERE o.Order_ID IS NULL;

-- OrderDetails with missing Products
SELECT 'Orphan OrderDetails (Product)', COUNT(*)
FROM orders.OrderDetails od
LEFT JOIN products.Product p ON od.Product_ID = p.Product_ID
WHERE p.Product_ID IS NULL;

-- Returned with missing Orders
SELECT 'Orphan Returned (Order)', COUNT(*)
FROM orders.Returned r
LEFT JOIN orders.Orders o ON r.Order_ID = o.Order_ID
WHERE o.Order_ID IS NULL;

-- Returned with missing Products
SELECT 'Orphan Returned (Product)', COUNT(*)
FROM orders.Returned r
LEFT JOIN products.Product p ON r.Product_ID = p.Product_ID
WHERE p.Product_ID IS NULL;

-- Payments with missing Orders
SELECT 'Orphan Payments (Order)', COUNT(*)
FROM orders.Payment p
LEFT JOIN orders.Orders o ON p.Order_ID = o.Order_ID
WHERE o.Order_ID IS NULL;

-- Reviews with missing Customers
SELECT 'Orphan Reviews (Customer)', COUNT(*)
FROM users.Review r
LEFT JOIN users.Customer c ON r.Cust_ID = c.Cust_ID
WHERE c.Cust_ID IS NULL;

-- Reviews with missing Products
SELECT 'Orphan Reviews (Product)', COUNT(*)
FROM users.Review r
LEFT JOIN products.Product p ON r.Product_ID = p.Product_ID
WHERE p.Product_ID IS NULL;

-- Reviews with missing Orders
SELECT 'Orphan Reviews (Order)', COUNT(*)
FROM users.Review r
LEFT JOIN orders.Orders o ON r.Order_ID = o.Order_ID
WHERE r.Order_ID IS NOT NULL AND o.Order_ID IS NULL;

-- Cart with missing Customers
SELECT 'Orphan Cart (Customer)', COUNT(*)
FROM cart.Cart c
LEFT JOIN users.Customer u ON c.Cust_ID = u.Cust_ID
WHERE u.Cust_ID IS NULL;

-- Cart Items with missing Products
SELECT 'Orphan Cart_Items (Product)', COUNT(*)
FROM cart.Cart_Items ci
LEFT JOIN products.Product p ON ci.Product_ID = p.Product_ID
WHERE p.Product_ID IS NULL;

-- Cart Items with missing Carts
SELECT 'Orphan Cart_Items (Cart)', COUNT(*)
FROM cart.Cart_Items ci
LEFT JOIN cart.Cart c ON ci.Cart_ID = c.Cart_ID
WHERE c.Cart_ID IS NULL;

-- Cart_Order with missing Cart
SELECT 'Orphan Cart_Order (Cart)', COUNT(*)
FROM cart.Cart_Order co
LEFT JOIN cart.Cart c ON co.Cart_ID = c.Cart_ID
WHERE c.Cart_ID IS NULL;

-- Cart_Order with missing Order
SELECT 'Orphan Cart_Order (Order)', COUNT(*)
FROM cart.Cart_Order co
LEFT JOIN orders.Orders o ON co.Order_ID = o.Order_ID
WHERE o.Order_ID IS NULL;

-- ========== Enum Validations ==========
SELECT 'Invalid Order Status', COUNT(*)
FROM orders.Orders 
WHERE Status NOT IN ('Pending', 'Shipped', 'Delivered', 'Cancelled', 'Returned');

SELECT 'Invalid Returned Status', COUNT(*)
FROM orders.Returned 
WHERE Status NOT IN ('Requested', 'Approved', 'Rejected', 'Processed');

SELECT 'Invalid Payment Method', COUNT(*)
FROM orders.Payment 
WHERE Payment_Method NOT IN ('Credit Card', 'Debit Card', 'PayPal', 'Cash on Delivery', 'Bank Transfer');

SELECT 'Invalid Payment Status', COUNT(*)
FROM orders.Payment 
WHERE Payment_Status NOT IN ('Pending', 'Completed', 'Failed', 'Refunded');

-- ========== Value Validations ==========
SELECT 'Negative Price or Stock in Product', COUNT(*) 
FROM products.Product 
WHERE Price < 0 OR Stock_Quantity < 0;

SELECT 'Invalid Quantity/Price in OrderDetails', COUNT(*)
FROM orders.OrderDetails 
WHERE Quantity <= 0 OR UnitPrice < 0;

SELECT 'Invalid Estimated Days/Cost in ShipMethod', COUNT(*)
FROM orders.ShipMethod 
WHERE Estimated_Days <= 0 OR Cost < 0;

SELECT 'Negative Amount in Payment', COUNT(*)
FROM orders.Payment 
WHERE Amount < 0;

SELECT 'Invalid Quantity in Cart_Items', COUNT(*)
FROM cart.Cart_Items 
WHERE Quantity <= 0;

-- ========== Uniqueness Violations ==========
SELECT 'Duplicate Emails', COUNT(*) 
FROM (
    SELECT Email FROM users.Customer 
    WHERE Email IS NOT NULL
    GROUP BY Email HAVING COUNT(*) > 1
) dup;

SELECT 'Duplicate Phones', COUNT(*) 
FROM (
    SELECT Phone FROM users.Customer 
    WHERE Phone IS NOT NULL
    GROUP BY Phone HAVING COUNT(*) > 1
) dup;

-- ========== Date Validations ==========
SELECT 'Invalid Dates (Ship/Due before Order)', COUNT(*) 
FROM orders.Orders
WHERE 
    (Ship_Date IS NOT NULL AND Ship_Date < Order_Date)
    OR (Due_Date IS NOT NULL AND Due_Date < ISNULL(Ship_Date, Order_Date));
	

--  NULL Checks
-- ==========================================

-- Products without names
SELECT 'Products with NULL Names', COUNT(*)
FROM products.Product
WHERE Product_Name IS NULL;

-- Customers without email addresses (if required)
SELECT 'Customers with NULL Emails', COUNT(*)
FROM users.Customer
WHERE Email IS NULL;

-- Shipping methods without cost
SELECT 'Ship Methods with NULL Cost', COUNT(*)
FROM orders.ShipMethod
WHERE Cost IS NULL;

-- OrderDetails with missing Quantity or UnitPrice
SELECT 'OrderDetails with NULL Quantity or UnitPrice', COUNT(*)
FROM orders.OrderDetails
WHERE Quantity IS NULL OR UnitPrice IS NULL;

-- Payments with missing Payment_Status
SELECT 'Payments with NULL Payment_Status', COUNT(*)
FROM orders.Payment
WHERE Payment_Status IS NULL;

------------------------------------------------------------

-- Cross-Field Validations
-- ==========================================

-- Validate Total = Quantity * UnitPrice (with 0.01 margin)
SELECT 'Mismatched Payment Amounts', COUNT(*)
FROM orders.Payment p
JOIN (
    SELECT 
        o.Order_ID,
        SUM(od.Quantity * od.UnitPrice) AS CalculatedTotal
    FROM orders.Orders o
    JOIN orders.OrderDetails od ON o.Order_ID = od.Order_ID
    GROUP BY o.Order_ID
) expected ON p.Order_ID = expected.Order_ID
WHERE ABS(p.Amount - expected.CalculatedTotal) > 0.01;

------------------------------------------------------------

--  Reverse Referential Integrity Checks
-- ==========================================

-- Customers who have never placed an order
SELECT 'Customers without Orders', COUNT(*)
FROM users.Customer c
LEFT JOIN orders.Orders o ON c.Cust_ID = o.Cust_ID
WHERE o.Order_ID IS NULL;

-- Products never purchased
SELECT 'Products without Sales', COUNT(*)
FROM products.Product p
LEFT JOIN orders.OrderDetails od ON p.Product_ID = od.Product_ID
WHERE od.Order_ID IS NULL;

------------------------------------------------------------

-- Business Rule Violations
-- ==========================================

-- Delivered orders with no associated payment
SELECT 'Delivered Orders without Payments', COUNT(*)
FROM orders.Orders o
LEFT JOIN orders.Payment p ON o.Order_ID = p.Order_ID
WHERE o.Status = 'Delivered' AND p.Payment_ID IS NULL;

-- Reviews with ratings outside valid range (e.g., 1 to 5)
SELECT 'Reviews with Invalid Ratings', COUNT(*)
FROM users.Review
WHERE Rating < 1 OR Rating > 5;

-- Products with NULL or zero price
SELECT 'Products with NULL or 0 Price', COUNT(*)
FROM products.Product
WHERE Price IS NULL OR Price = 0;

------------------------------------------------------------


--Basic Statistical Anomaly Checks
-- ==========================================

-- Products with extremely high prices (above 3x average)
SELECT 'Price Outliers (Very Expensive Products)', COUNT(*)
FROM products.Product
WHERE Price > (
    SELECT AVG(Price) * 3 FROM products.Product
);

-- Customers with unusually high order count (>100 orders)
SELECT 'High Volume Customers (>100 Orders)', COUNT(*)
FROM (
    SELECT Cust_ID, COUNT(*) AS OrderCount
    FROM orders.Orders
    GROUP BY Cust_ID
    HAVING COUNT(*) > 100
) HighVolume;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM users.Customer c
            LEFT JOIN orders.Orders o ON c.Cust_ID = o.Cust_ID
            WHERE o.Order_ID IS NULL
        )
        THEN ' No – Some customers have no orders'
        ELSE 'Yes – All customers have at least one order'
    END AS Result;

	SELECT COUNT(*) FROM users.Customer;
	SELECT COUNT(DISTINCT Cust_ID) FROM orders.Orders;

	SELECT 
    (SELECT SUM(Total_Amount) FROM orders.Orders) AS Total_Order_Amount,
    (SELECT SUM(Amount) FROM orders.Payment) AS Total_Payment_Amount,
    (SELECT SUM(UnitPrice * Quantity) FROM orders.OrderDetails) AS Calculated_OrderDetails_Total;

SELECT 'Delivered Orders without Payments', COUNT(DISTINCT o.Order_ID)
FROM orders.Orders o
LEFT JOIN orders.Payment p ON o.Order_ID = p.Order_ID
WHERE o.Status = 'Delivered' AND p.Payment_ID IS NULL;

SELECT COUNT(*) AS TotalOrders FROM orders.Orders;

SELECT COUNT(*) AS DeliveredOrders
FROM orders.Orders
WHERE Status = 'Delivered';

SELECT COUNT(DISTINCT o.Order_ID) AS DeliveredWithoutPayment
FROM orders.Orders o
LEFT JOIN orders.Payment p ON o.Order_ID = p.Order_ID
WHERE o.Status = 'Delivered' AND p.Payment_ID IS NULL;

SELECT Status, COUNT(*) AS Order_Count
FROM orders.Orders
WHERE Status IN ('Cancelled', 'Pending','Delivered')
GROUP BY Status;



