-- ========================================
-- 1) DROP & CREATE DATABASE
-- ========================================
DROP DATABASE IF EXISTS SupermarketDB;
CREATE DATABASE SupermarketDB;
USE SupermarketDB;

-- ========================================
-- 2) CREATE TABLES (unchanged)
-- ========================================
CREATE TABLE SuperMarket (
  supermarket_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  headquarters VARCHAR(255)
);

CREATE TABLE Branch (
  branch_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  location VARCHAR(255),
  supermarket_id INT,
  FOREIGN KEY (supermarket_id) REFERENCES SuperMarket(supermarket_id) ON DELETE CASCADE
);

CREATE TABLE Department (
  department_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  branch_id INT,
  FOREIGN KEY (branch_id) REFERENCES Branch(branch_id) ON DELETE CASCADE
);

CREATE TABLE Employee (
  employee_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(100),
  salary DECIMAL(10,2) CHECK (salary >= 0),
  branch_id INT,
  department_id INT,
  FOREIGN KEY (branch_id)    REFERENCES Branch(branch_id)   ON DELETE SET NULL,
  FOREIGN KEY (department_id)REFERENCES Department(department_id) ON DELETE SET NULL
);

CREATE TABLE Customer (
  customer_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) UNIQUE,
  email VARCHAR(255) UNIQUE
);

CREATE TABLE Supplier (
  supplier_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  contact VARCHAR(20)
);

CREATE TABLE Product (
  product_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(100),
  price DECIMAL(10,2) NOT NULL CHECK (price > 0),
  supplier_id INT,
  FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id) ON DELETE SET NULL
);

CREATE TABLE Stock (
  stock_id INT PRIMARY KEY AUTO_INCREMENT,
  branch_id INT,
  product_id INT,
  quantity INT NOT NULL CHECK (quantity >= 0),
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (branch_id)  REFERENCES Branch(branch_id)  ON DELETE CASCADE,
  FOREIGN KEY (product_id)REFERENCES Product(product_id) ON DELETE CASCADE
);

CREATE TABLE Billing (
  billing_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT,
  branch_id INT,
  total_amount DECIMAL(10,2) DEFAULT 0 CHECK (total_amount >= 0),
  billing_date DATE NOT NULL,
  payment_method ENUM('Cash','Card','Online'),
  FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) ON DELETE CASCADE,
  FOREIGN KEY (branch_id)    REFERENCES Branch(branch_id)    ON DELETE CASCADE
);

CREATE TABLE Billing_Product (
  billing_id INT,
  product_id INT,
  quantity INT NOT NULL CHECK (quantity > 0),
  PRIMARY KEY (billing_id, product_id),
  FOREIGN KEY (billing_id) REFERENCES Billing(billing_id) ON DELETE CASCADE,
  FOREIGN KEY (product_id)REFERENCES Product(product_id) ON DELETE CASCADE
);

CREATE TABLE Cleaning_Company (
  company_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  contact VARCHAR(20)
);

CREATE TABLE Branch_CleaningCompany (
  branch_id INT,
  company_id INT,
  service_frequency ENUM('Daily','Weekly','Monthly'),
  PRIMARY KEY (branch_id, company_id),
  FOREIGN KEY (branch_id)  REFERENCES Branch(branch_id)          ON DELETE CASCADE,
  FOREIGN KEY (company_id)REFERENCES Cleaning_Company(company_id) ON DELETE CASCADE
);

-- ========================================
-- 3) SQL FUNCTIONS (new)
-- ========================================

DELIMITER $$
CREATE FUNCTION get_department_emp_count(dept_id INT) 
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE cnt INT;
  SELECT COUNT(*) INTO cnt
    FROM Employee
    WHERE department_id = dept_id;
  RETURN IFNULL(cnt,0);
END$$

CREATE FUNCTION get_branch_stock_value(branch INT) 
RETURNS DECIMAL(12,2) DETERMINISTIC
BEGIN
  DECLARE total DECIMAL(12,2);
  SELECT SUM(s.quantity * p.price) INTO total
    FROM Stock s
    JOIN Product p ON s.product_id = p.product_id
    WHERE s.branch_id = branch;
  RETURN IFNULL(total,0);
END$$
DELIMITER ;

-- ========================================
-- 4) SEED DEFAULT DATA (unchanged)
-- ========================================
INSERT INTO SuperMarket (name, headquarters) VALUES ('DefaultMart','HQ City');
INSERT INTO Customer (name, phone, email) VALUES
  ('Test Customer 1','1111111111','c1@demo.com'),
  ('Test Customer 2','2222222222','c2@demo.com');

-- ========================================
-- 5) DROP EXISTING ROLES & USERS
-- ========================================
DROP ROLE IF EXISTS branch_manager, cashier, inventory_clerk, supplier_rep, analyst,
                    department_mgr, cleaning_mgr, supplier_mgr, auditor;
DROP USER IF EXISTS 'mgr'@'%', 'cash'@'%', 'inv'@'%', 'sup'@'%',
                   'ana'@'%', 'dept'@'%', 'clean'@'%', 'sman'@'%', 'audit'@'%';

-- ========================================
-- 6) CREATE ROLES & USERS (new roles)
-- ========================================
CREATE ROLE branch_manager;
CREATE ROLE department_mgr;
CREATE ROLE cleaning_mgr;
CREATE ROLE supplier_mgr;
CREATE ROLE cashier;
CREATE ROLE inventory_clerk;
CREATE ROLE supplier_rep;
CREATE ROLE analyst;
CREATE ROLE auditor;

CREATE USER 'mgr'@'%'    IDENTIFIED BY 'm123';
CREATE USER 'dept'@'%'   IDENTIFIED BY 'd123';
CREATE USER 'clean'@'%'  IDENTIFIED BY 'cl123';
CREATE USER 'sman'@'%'   IDENTIFIED BY 'sm123';
CREATE USER 'cash'@'%'   IDENTIFIED BY 'c123';
CREATE USER 'inv'@'%'    IDENTIFIED BY 'i123';
CREATE USER 'sup'@'%'    IDENTIFIED BY 's123';
CREATE USER 'ana'@'%'    IDENTIFIED BY 'a123';
CREATE USER 'audit'@'%'  IDENTIFIED BY 'au123';

GRANT branch_manager  TO 'mgr'@'%';
GRANT department_mgr TO 'dept'@'%';
GRANT cleaning_mgr   TO 'clean'@'%';
GRANT supplier_mgr   TO 'sman'@'%';
GRANT cashier        TO 'cash'@'%';
GRANT inventory_clerk TO 'inv'@'%';
GRANT supplier_rep   TO 'sup'@'%';
GRANT analyst        TO 'ana'@'%';
GRANT auditor        TO 'audit'@'%';

-- set default roles
ALTER USER 'mgr'@'%'    DEFAULT ROLE branch_manager;
ALTER USER 'dept'@'%'   DEFAULT ROLE department_mgr;
ALTER USER 'clean'@'%'  DEFAULT ROLE cleaning_mgr;
ALTER USER 'sman'@'%'   DEFAULT ROLE supplier_mgr;
ALTER USER 'cash'@'%'   DEFAULT ROLE cashier;
ALTER USER 'inv'@'%'    DEFAULT ROLE inventory_clerk;
ALTER USER 'sup'@'%'    DEFAULT ROLE supplier_rep;
ALTER USER 'ana'@'%'    DEFAULT ROLE analyst;
ALTER USER 'audit'@'%'  DEFAULT ROLE auditor;

-- ========================================
-- 7) GRANT PRIVILEGES (expanded)
-- ========================================
-- Branch Manager: full CRUD on Branch & Department
GRANT SELECT, INSERT, UPDATE, DELETE ON SupermarketDB.Branch TO branch_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON SupermarketDB.Department TO branch_manager;

-- Department Manager: manage employees in their dept
GRANT SELECT, INSERT, UPDATE, DELETE ON SupermarketDB.Employee TO department_mgr;

-- Cleaning Manager: manage cleaning assignments
GRANT SELECT, INSERT, UPDATE, DELETE ON SupermarketDB.Cleaning_Company TO cleaning_mgr;
GRANT SELECT, INSERT, UPDATE, DELETE ON SupermarketDB.Branch_CleaningCompany TO cleaning_mgr;

-- Supplier Manager: full CRUD on Supplier & Product
GRANT SELECT, INSERT, UPDATE, DELETE ON SupermarketDB.Supplier TO supplier_mgr;
GRANT SELECT, INSERT, UPDATE, DELETE ON SupermarketDB.Product TO supplier_mgr;

-- Cashier: bills
GRANT SELECT, INSERT ON SupermarketDB.Billing TO cashier;
GRANT SELECT, INSERT ON SupermarketDB.Billing_Product TO cashier;

-- Inventory Clerk: stock & products
GRANT SELECT, INSERT, UPDATE, DELETE ON SupermarketDB.Stock TO inventory_clerk;
GRANT SELECT ON SupermarketDB.Product TO inventory_clerk;

-- Supplier Rep: view products
GRANT SELECT ON SupermarketDB.Product TO supplier_rep;

-- Analyst: read-only across all + use functions
GRANT SELECT ON SupermarketDB.* TO analyst;

-- Auditor: read-only + EXECUTE on functions
GRANT SELECT ON SupermarketDB.* TO auditor;
GRANT EXECUTE ON FUNCTION SupermarketDB.get_department_emp_count TO auditor;
GRANT EXECUTE ON FUNCTION SupermarketDB.get_branch_stock_value TO auditor;

FLUSH PRIVILEGES;

USE SupermarketDB;

-- 1. SuperMarket
INSERT INTO SuperMarket (name, headquarters) VALUES
('FreshMart', 'New York'),
('ValueShop', 'Los Angeles'),
('QuickBuy', 'Chicago'),
('MarketPlus', 'Houston'),
('DailyNeeds', 'Phoenix'),
('BudgetGoods', 'Philadelphia'),
('GreenGrocer', 'San Antonio'),
('MegaMart', 'San Diego'),
('CityStore', 'Dallas'),
('FamilyMart', 'San Jose');

-- 2. Branch (linked to supermarket_id 1–10)
INSERT INTO Branch (name, location, supermarket_id) VALUES
('FreshMart Central', 'Manhattan', 1),
('ValueShop East', 'Pasadena', 2),
('QuickBuy South', 'Hyde Park', 3),
('MarketPlus North', 'Katy', 4),
('DailyNeeds South', 'Tempe', 5),
('BudgetGoods North', 'Downtown', 6),
('GreenGrocer East', 'Downtown SA', 7),
('MegaMart Central', 'Gaslamp', 8),
('CityStore West', 'Frisco', 9),
('FamilyMart East', 'Santa Clara', 10);

-- 3. Department (linked to branch_id 1–10)
INSERT INTO Department (name, branch_id) VALUES
('Groceries', 1),
('Electronics', 2),
('Clothing', 3),
('Pharmacy', 4),
('Home Goods', 5),
('Toys', 6),
('Bakery', 7),
('Produce', 8),
('Meat', 9),
('Seafood', 10);

-- 4. Employee (linked to branch_id and department_id 1–10)
INSERT INTO Employee (name, role, salary, branch_id, department_id) VALUES
('John Doe', 'Cashier', 2800.00, 1, 1),
('Jane Smith', 'Manager', 5500.00, 2, 2),
('Alice Johnson', 'Sales Associate', 3000.00, 3, 3),
('Bob Williams', 'Pharmacist', 5200.00, 4, 4),
('Carol White', 'Home Specialist', 3500.00, 5, 5),
('David Lee', 'Toy Associate', 3200.00, 6, 6),
('Eva Brown', 'Baker', 3000.00, 7, 7),
('Frank Green', 'Produce Clerk', 2900.00, 8, 8),
('Grace Black', 'Meat Cutter', 3100.00, 9, 9),
('Henry King', 'Seafood Clerk', 3300.00, 10, 10);

-- 5. Customer
INSERT INTO Customer (name, phone, email) VALUES
('Michael Brown','111-111-1111','michael@example.com'),
('Sarah Davis','222-222-2222','sarah@example.com'),
('David Wilson','333-333-3333','david@example.com'),
('Emma Martinez','444-444-4444','emma@example.com'),
('Liam Anderson','555-555-5555','liam@example.com'),
('Olivia Thomas','666-666-6666','olivia@example.com'),
('Noah Jackson','777-777-7777','noah@example.com'),
('Ava White','888-888-8888','ava@example.com'),
('Isabella Harris','999-999-9999','isabella@example.com'),
('Mason Martin','000-000-0000','mason@example.com');

-- 6. Supplier
INSERT INTO Supplier (name, contact) VALUES
('Global Foods Ltd.','101-101-1010'),
('ElectroWorld','202-202-2020'),
('FashionHub','303-303-3030'),
('MediCare Inc.','404-404-4040'),
('HomeEssentials','505-505-5050'),
('ToyLand','606-606-6060'),
('BakeHouse','707-707-7070'),
('FreshProduce Co.','808-808-8080'),
('MeatKing','909-909-9090'),
('SeaHarvest','121-212-1212');

-- 7. Product (linked to supplier_id 1–10)
INSERT INTO Product (name, category, price, supplier_id) VALUES
('Apple','Fruits',1.20,1),
('LED TV','Electronics',450.00,2),
('Jeans','Clothing',40.00,3),
('Pain Relief','Medicine',8.50,4),
('Blender','Home Goods',25.00,5),
('Toy Car','Toys',15.00,6),
('Bread','Bakery',2.50,7),
('Carrots','Produce',1.00,8),
('Chicken Breast','Meat',5.50,9),
('Salmon Fillet','Seafood',9.00,10);

-- 8. Stock (linked to branch_id 1–10 and product_id 1–10)
INSERT INTO Stock (branch_id, product_id, quantity) VALUES
(1,1,100),
(2,2,50),
(3,3,75),
(4,4,60),
(5,5,80),
(6,6,90),
(7,7,40),
(8,8,120),
(9,9,110),
(10,10,55);

-- 9. Billing (linked to customer_id 1–10 and branch_id 1–10)
INSERT INTO Billing (customer_id, branch_id, total_amount, billing_date, payment_method) VALUES
(1,1,12.00,'2025-04-01','Cash'),
(2,2,40.00,'2025-04-02','Card'),
(3,3,8.50,'2025-04-03','Online'),
(4,4,25.00,'2025-04-04','Cash'),
(5,5,15.00,'2025-04-05','Card'),
(6,6,2.50,'2025-04-06','Online'),
(7,7,180.00,'2025-04-07','Cash'),
(8,8,90.00,'2025-04-08','Card'),
(9,9,55.00,'2025-04-09','Online'),
(10,10,30.00,'2025-04-10','Cash');

-- 10. Billing_Product (linked to billing_id 1–10 and product_id 1–10)
INSERT INTO Billing_Product (billing_id, product_id, quantity) VALUES
(1,1,10),
(2,2,1),
(3,3,2),
(4,4,1),
(5,5,2),
(6,6,1),
(7,7,3),
(8,8,2),
(9,9,5),
(10,10,1);

-- 11. Cleaning_Company
INSERT INTO Cleaning_Company (name, contact) VALUES
('Sparkle Cleaners','111-222-3333'),
('Fresh & Tidy','222-333-4444'),
('UltraClean','333-444-5555'),
('EcoShine','444-555-6666'),
('CleanWorks','555-666-7777'),
('ProClean','666-777-8888'),
('ShineBright','777-888-9999'),
('QuickClean','888-999-0000'),
('Spotless','999-000-1111'),
('SuperBrite','101-202-3030');

-- 12. Branch_CleaningCompany (branch_id 1–10 + company_id 1–10)
INSERT INTO Branch_CleaningCompany (branch_id, company_id, service_frequency) VALUES
(1,1,'Daily'),
(2,2,'Weekly'),
(3,3,'Monthly'),
(4,4,'Daily'),
(5,5,'Weekly'),
(6,6,'Monthly'),
(7,7,'Daily'),
(8,8,'Weekly'),
(9,9,'Monthly'),
(10,10,'Daily');
