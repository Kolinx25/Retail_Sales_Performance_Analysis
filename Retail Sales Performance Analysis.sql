/*Project: Retail Sales Performance Analysis
Dataset: Maven Analytics - Northwind Traders (free download)*/

--The Business Problem
/*"The sales manager wants to understand which customers,
products, and employees are driving revenue and identify
where the business is losing money."*/

--First Need to create a database to store and organize all the data
CREATE DATABASE NorthWindDB;
GO
--USE syntax is used to active the desired database
USE NorthWindDB;
GO

--Time to create the tables 
--This creates the table 'category' and set the columns & accepted data types.
CREATE TABLE Categories
(
    categoryID INT PRIMARY KEY,
    categoryName VARCHAR(500),
    descriptions NVARCHAR(MAX)
);

--inserting the datasets using bulk insert
BULK INSERT categories
FROM 'C:/Users/Collins Amoo/Desktop/SQL Prj 1/Retail Sales Performance Analysis/Northwind Traders/categories.csv'
WITH (
    FORMAT = 'CSV',  -- The file format being imported
    FIRSTROW = 2,    -- -- This tells SQL to start from the second row since the first row contains column headers
    FIELDTERMINATOR = ',',  --Columns in the CSV are separated by commas
    ROWTERMINATOR = '\n',  --Each new line represents a new row of data
    TABLOCK            --Locks the table during import for faster performance
);


CREATE TABLE Customers
(
    customerID VARCHAR(5) PRIMARY KEY,
    companyName VARCHAR(500),
    contactName VARCHAR(255),
    contactTitle VARCHAR(255),
    city VARCHAR(255),
    country VARCHAR(255)
);

BULK INSERT customers
FROM 'C:/Users/Collins Amoo/Desktop/SQL Prj 1/Retail Sales Performance Analysis/Northwind Traders/customers.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'  

);

CREATE TABLE employees
(
    employeeID INT PRIMARY KEY,
    employeeName VARCHAR(500),
    title VARCHAR(255),
    city VARCHAR(255),
    country VARCHAR(255),
    reportsTo INT,

    CONSTRAINT fk_reports_to
FOREIGN KEY (reportsTo) REFERENCES employees(employeeID)
);

BULK INSERT Employees
FROM 'C:/Users/Collins Amoo/Desktop/SQL Prj 1/Retail Sales Performance Analysis/Northwind Traders/employees.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'  
);

CREATE TABLE shippers
(
    shipperID INT PRIMARY KEY,
    companyName NVARCHAR(MAX)

);


BULK INSERT shippers
FROM 'C:/Users/Collins Amoo/Desktop/SQL Prj 1/Retail Sales Performance Analysis/Northwind Traders/shippers.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'  
);

CREATE TABLE orders
(
    orderID INT PRIMARY KEY,
    customerID VARCHAR(5),
    employeeID INT,
    orderDate DATE,
    requiredDate DATE,
    shippedDate DATE,
    shipperID INT,
    freight DECIMAL(10,2),

    CONSTRAINT fk_order_customer FOREIGN KEY (customerID) REFERENCES Customers(customerID),
    CONSTRAINT fk_order_employee FOREIGN KEY (employeeID) REFERENCES Employees(EmployeeID),
    CONSTRAINT fk_order_shipper FOREIGN KEY (shipperID) REFERENCES shippers(shipperID)
);

BULK INSERT orders
FROM 'C:/Users/Collins Amoo/Desktop/SQL Prj 1/Retail Sales Performance Analysis/Northwind Traders/orders.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'  
);

CREATE TABLE products
(
    productID INT PRIMARY KEY,
    productName VARCHAR(255),
    quantityPerUnit VARCHAR(255),
    unitPrice DECIMAL(10,2),
    discontinued INT,
    categoryID INT,

    CONSTRAINT fk_product_category 
        FOREIGN KEY (categoryID) REFERENCES Categories(categoryID)
);

BULK INSERT products
FROM 'C:/Users/Collins Amoo/Desktop/SQL Prj 1/Retail Sales Performance Analysis/Northwind Traders/products.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'  
);


CREATE TABLE order_details
(
    orderID INT ,
    productID INT,
    unitPrice DECIMAL(10,2),
    quantity INT,
    discount FLOAT,

    PRIMARY KEY(orderID,productID),
    CONSTRAINT fk_details_order
   FOREIGN KEY(orderID) REFERENCES orders(orderID),
    CONSTRAINT fk_details_products
   FOREIGN KEY(productID) REFERENCES products(productID)

);

BULK INSERT order_details
FROM 'C:/Users/Collins Amoo/Desktop/SQL Prj 1/Retail Sales Performance Analysis/Northwind Traders/order_details.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'  
);


/*Q1.What are the top 10 best-selling products by revenue?*/

SELECT TOP 10
    p.productID,
    p.productName,
    SUM(od.quantity * od.unitPrice) AS TotalRevenue
FROM products AS p
    LEFT JOIN order_details AS od
    ON p.productID = od.productID
GROUP BY p.productID, p.productName
ORDER BY TotalRevenue DESC;

/*Q2.Which employees handled orders for high-value customers?*/
SELECT
    e.employeeName, e.employeeID, c.companyName, SUM(od.quantity*od.unitPrice) AS TotalRevenue
FROM employees AS e
    LEFT JOIN orders AS o ON e.employeeID = o.employeeID
    LEFT JOIN order_details AS od ON od.orderID = o.orderID
    LEFT JOIN Customers AS c ON c.customerID =o.customerID
GROUP BY e.employeeName,e.employeeID,c.companyName
ORDER BY TotalRevenue DESC;


/*Q3.Are there customers who haven't placed orders in over 90 days?*/
SELECT
    c.companyName,
    c.customerID,
    MAX(o.orderDate) AS LastOrderDate,
    DATEDIFF(day, MAX(o.orderDate), GETDATE()) AS DaysSinceLastOrder
FROM orders AS o
    LEFT JOIN customers AS c
    ON o.customerID = c.customerID
GROUP BY c.customerID, c.companyName
HAVING DATEDIFF(day, MAX(o.orderDate), GETDATE()) > 90
ORDER BY DaysSinceLastOrder DESC;

/*Q4.Which country generates the most sales?*/
SELECT
    c.country, SUM(od.quantity*od.unitPrice) AS TotalSales
FROM Customers AS c
    LEFT JOIN orders AS o ON c.customerID=o.customerID
    LEFT JOIN order_details AS od ON o.orderID=od.orderID
GROUP BY c.country
ORDER BY TotalSales DESC;

/*Q5.Which product category generates the most revenue?*/

SELECT
    ca.categoryName,
    SUM(od.quantity * od.unitPrice) AS TotalRevenue
FROM Categories AS ca
    LEFT JOIN products AS p ON ca.categoryID = p.categoryID
    LEFT JOIN order_details AS od ON p.productID = od.productID
GROUP BY ca.categoryName
ORDER BY TotalRevenue DESC;

/*Q6.Who is the top performing employee by total sales?*/

SELECT
    e.employeeName, SUM(od.quantity*od.unitPrice) AS TotalSalesByemp
FROM employees AS e
    LEFT JOIN orders AS o ON e.employeeID=o.employeeID
    LEFT JOIN order_details AS od ON o.orderID=od.orderID
GROUP BY e.employeeName
ORDER BY TotalSalesByemp DESC;

/*Q7.What is the average order value per customer?*/
SELECT
    c.companyName, SUM(od.quantity * od.unitPrice) / COUNT(DISTINCT o.orderID) AS AvgOrderValue
FROM Customers AS c
    LEFT JOIN orders AS o ON c.customerID=o.customerID
    LEFT JOIN order_details AS od ON od.orderID=o.orderID
GROUP BY c.companyName
ORDER BY AvgOrderValue DESC;

/*Q8.Which shipping company is used the most?*/
SELECT
    s.companyName,
    COUNT(o.orderID) AS TotalOrders
FROM shippers AS s
    LEFT JOIN orders AS o ON s.shipperID = o.shipperID
GROUP BY s.companyName
ORDER BY TotalOrders DESC;

/*Q9.Which customers have never placed an order?*/
SELECT
    c.companyName
FROM Customers AS c
    LEFT JOIN orders AS o ON c.customerID=o.customerID
    LEFT JOIN order_details AS od ON o.orderID=od.orderID
WHERE o.orderID IS NULL

/*Q10.Which customers have placed the most orders?*/

SELECT
    c.companyName, c.country, c.city, COUNT(orderID) as TotalOrders
FROM Customers AS c
    LEFT JOIN Orders AS o
    ON c.customerID=o.customerID
GROUP BY c.companyName,c.country,c.city
ORDER BY TotalOrders DESC;
    GO