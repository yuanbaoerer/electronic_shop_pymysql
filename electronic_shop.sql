-- Check if the database exists and drop it if it does
DROP DATABASE IF EXISTS electronics_shop;

-- Create database
CREATE DATABASE electronics_shop
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- Use the database
USE electronics_shop;

-- Check if Vendor table exists and drop it if it does
DROP TABLE IF EXISTS Vendor;
-- Vendor table (removed static rating field)
CREATE TABLE Vendor (
    vendor_id VARCHAR(20) PRIMARY KEY,
    business_name VARCHAR(100) NOT NULL,
    geographical_presence VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Check if Customer table exists and drop it if it does
DROP TABLE IF EXISTS Customer;
-- Customer table
CREATE TABLE Customer (
    customer_id VARCHAR(20) PRIMARY KEY,
    contact_number VARCHAR(15) NOT NULL,
    shipping_address VARCHAR(200),
    shipping_state VARCHAR(50) DEFAULT 'Not shipped yet.'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Check if Product table exists and drop it if it does
DROP TABLE IF EXISTS Product;
-- Product table (up to 3 tags)
CREATE TABLE Product (
    product_id VARCHAR(20) PRIMARY KEY,
    vendor_id VARCHAR(20) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    listed_price DECIMAL(10,2) NOT NULL,
    tag1 VARCHAR(50),
    tag2 VARCHAR(50),
    tag3 VARCHAR(50),
    inventory INT DEFAULT 0,
    FOREIGN KEY (vendor_id) REFERENCES Vendor(vendor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Check if Orders table exists and drop it if it does
DROP TABLE IF EXISTS Orders;
-- Orders table (status defaults to pending)
CREATE TABLE Orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    order_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending',
    tracking_number VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Check if OrderDetail table exists and drop it if it does
DROP TABLE IF EXISTS OrderDetail;
-- OrderDetail table (added rating field)
CREATE TABLE OrderDetail (
    order_detail_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(20) NOT NULL,
    product_id VARCHAR(20) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    rating DECIMAL(3,1) CHECK (rating BETWEEN 0.0 AND 5.0),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Check if VendorScores view exists and drop it if it does
DROP VIEW IF EXISTS VendorScores;
-- Vendor rating view (dynamically calculates average score)
-- Updated VendorScores view
CREATE OR REPLACE VIEW VendorScores AS
SELECT
    v.vendor_id,
    v.business_name,
    ROUND(AVG(od.rating), 1) AS feedback_score
FROM Vendor v
LEFT JOIN Product p ON v.vendor_id = p.vendor_id
LEFT JOIN OrderDetail od ON p.product_id = od.product_id AND od.rating IS NOT NULL
GROUP BY v.vendor_id;

-- Insert initial vendor data
INSERT INTO Vendor (vendor_id, business_name, geographical_presence)
VALUES
    ('V_DJI', 'DJI', 'China'),
    ('V_SAMSUNG', 'Samsung', 'Korea'),
    ('V_SONY', 'Sony', 'Japan'),
    ('V_APPLE', 'Apple', 'America'),
    ('V_HUAWEI', 'HUAWEI', 'China'),
    ('V_FUJIFILM', 'Fuji', 'Japan');

-- Insert sample products
-- ------------------------- DJI (V_DJI) 5 products -------------------------
INSERT INTO Product (product_id, vendor_id, product_name, listed_price, tag1, tag2, tag3, inventory)
VALUES
    ('P_DJI_MAVIC4', 'V_DJI', 'DJI Mavic 4 Pro Drone', 14999.00, 'Drone', '8K', 'Professional', 40),
    ('P_DJI_MINI4', 'V_DJI', 'DJI Mini 4 Pro Drone', 5499.00, 'Portable', 'Lightweight', 'Smart Tracking', 120),
    ('P_DJI_RS4', 'V_DJI', 'DJI RS 4 Gimbal Stabilizer', 3599.00, 'Stabilizer', 'Cinematography', 'Wireless Control', 60),
    ('P_DJI_POCKET3', 'V_DJI', 'DJI Pocket 3 Handheld Camera', 3999.00, 'Vlog', '4K', 'Anti-shake', 150),
    ('P_DJI_AIR3', 'V_DJI', 'DJI Air 3 Aerial Drone', 8999.00, 'Dual Camera', 'Long Battery Life', 'Obstacle Avoidance', 80);

-- ------------------------- Samsung (V_SAMSUNG) 5 products -------------------------
INSERT INTO Product (product_id, vendor_id, product_name, listed_price, tag1, tag2, tag3, inventory)
VALUES
    ('P_SAMSUNG_S24', 'V_SAMSUNG', 'Samsung Galaxy S24 Ultra', 9999.00, 'Smartphone', '5G', 'AI Photography', 180),
    ('P_SAMSUNG_ZFLIP5', 'V_SAMSUNG', 'Samsung Galaxy Z Flip5', 8999.00, 'Foldable', 'Portable', 'Fashion', 90),
    ('P_SAMSUNG_QN95C', 'V_SAMSUNG', 'Samsung Neo QLED 8K TV', 34999.00, 'TV', '8K', 'Mini LED', 25),
    ('P_SAMSUNG_BUD2PRO', 'V_SAMSUNG', 'Samsung Buds2 Pro Earbuds', 1299.00, 'Noise Cancelling', 'Wireless', 'Hi-Fi', 300),
    ('P_SAMSUNG_T9', 'V_SAMSUNG', 'Samsung T9 Portable SSD', 1299.00, 'Storage', 'High Speed', 'Shockproof', 150);

-- ------------------------- Sony (V_SONY) 5 products -------------------------
INSERT INTO Product (product_id, vendor_id, product_name, listed_price, tag1, tag2, tag3, inventory)
VALUES
    ('P_SONY_A7M5', 'V_SONY', 'Sony A7M5 Full-frame Camera', 21999.00, 'Camera', '8K', 'AI Focus', 25),
    ('P_SONY_WHXM6', 'V_SONY', 'Sony WH-1000XM6 Headphones', 2999.00, 'Noise Cancelling', 'Wireless', 'Long Battery Life', 200),
    ('P_SONY_PS5PRO', 'V_SONY', 'Sony PS5 Pro Gaming Console', 4999.00, 'Gaming', '4K', 'Ray Tracing', 50),
    ('P_SONY_A6700', 'V_SONY', 'Sony A6700 Mirrorless Camera', 12999.00, 'APS-C', 'Vlog', 'Lightweight', 70),
    ('P_SONY_X95L', 'V_SONY', 'Sony X95L Mini LED TV', 18999.00, 'TV', '4K', 'XR Chip', 35);

-- ------------------------- Apple (V_APPLE) 5 products -------------------------
INSERT INTO Product (product_id, vendor_id, product_name, listed_price, tag1, tag2, tag3, inventory)
VALUES
    ('P_APPLE_IPHONE15', 'V_APPLE', 'iPhone 15 Pro Max', 10999.00, 'Smartphone', 'Titanium', 'A17 Chip', 200),
    ('P_APPLE_VISIONPRO', 'V_APPLE', 'Apple Vision Pro Headset', 25999.00, 'VR', 'Spatial Computing', '3D Interface', 30),
    ('P_APPLE_MACBOOKAIR', 'V_APPLE', 'MacBook Air 15-inch', 12999.00, 'Ultra-thin', 'M2 Chip', 'Retina', 100),
    ('P_APPLE_AIRPODS3', 'V_APPLE', 'AirPods 3rd Gen', 1399.00, 'Wireless', 'Spatial Audio', 'Waterproof', 400),
    ('P_APPLE_IPTV', 'V_APPLE', 'Apple TV 4K', 1499.00, 'Streaming', 'HDR', 'Gaming', 150);

-- ------------------------- HUAWEI (V_HUAWEI) 5 products -------------------------
INSERT INTO Product (product_id, vendor_id, product_name, listed_price, tag1, tag2, tag3, inventory)
VALUES
    ('P_HUAWEI_MATE60', 'V_HUAWEI', 'HUAWEI Mate 60 RS', 13999.00, 'Smartphone', 'Satellite Communication', 'Kunlun Glass', 100),
    ('P_HUAWEI_MATEPAD2', 'V_HUAWEI', 'HUAWEI MatePad Pro 13.2', 5999.00, 'Tablet', 'OLED', 'HarmonyOS', 80),
    ('P_HUAWEI_WATCH4', 'V_HUAWEI', 'HUAWEI Watch 4 Pro', 2699.00, 'Health Monitoring', 'eSIM', 'Titanium', 120),
    ('P_HUAWEI_FREEBUDS3', 'V_HUAWEI', 'HUAWEI FreeBuds Pro 3', 1499.00, 'Noise Cancelling', 'Spatial Audio', 'Hi-Res', 250),
    ('P_HUAWEI_MATEVIEW', 'V_HUAWEI', 'HUAWEI MateView Monitor', 7999.00, '4K', 'Touch Screen', 'Wireless Casting', 60);

-- ------------------------- Fujifilm (V_FUJIFILM) 5 products -------------------------
INSERT INTO Product (product_id, vendor_id, product_name, listed_price, tag1, tag2, tag3, inventory)
VALUES
    ('P_FUJI_XT6', 'V_FUJIFILM', 'Fujifilm X-T6 Mirrorless Camera', 13999.00, 'Retro', 'APS-C', 'Film Simulation', 40),
    ('P_FUJI_GFX100S', 'V_FUJIFILM', 'Fujifilm GFX100S Medium Format', 45999.00, 'Medium Format', '102MP', 'Image Stabilization', 20),
    ('P_FUJI_INSTAX', 'V_FUJIFILM', 'Fujifilm Instax Mini 12', 599.00, 'Instant Camera', 'Portable', 'Instant Print', 300),
    ('P_FUJI_X100V', 'V_FUJIFILM', 'Fujifilm X100V Digital Camera', 10999.00, 'Rangefinder', 'Prime Lens', 'Retro', 50),
    ('P_FUJI_XS20', 'V_FUJIFILM', 'Fujifilm X-S20 Vlog Camera', 8999.00, 'Vlog', 'Lightweight', '4K', 70);

-- Insert 5 customers with default shipping status
INSERT INTO Customer (customer_id, contact_number, shipping_address)
VALUES
    ('C001', '13800000001', 'No.1 Zhongguancun Street, Haidian District, Beijing'),
    ('C002', '13800000002', 'No.100 Zhangjiang Road, Pudong New Area, Shanghai'),
    ('C003', '13800000003', 'No.8 Huaqiang Road, Zhujiang New Town, Tianhe District, Guangzhou'),
    ('C004', '13800000004', 'No.10 Keyuan Road, Science Park, Nanshan District, Shenzhen'),
    ('C005', '13800000005', 'No.399 Wensan Road, Xihu District, Hangzhou');

-- Order records
INSERT INTO Orders (order_id, customer_id, order_date)
VALUES ('O001', 'C001', '2023-10-01');

-- Order details (DJI, Apple, Sony)
INSERT INTO OrderDetail (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES
    ('O001_1', 'O001', 'P_DJI_MAVIC4', 1, 14999.00),
    ('O001_2', 'O001', 'P_APPLE_IPHONE15', 1, 10999.00),
    ('O001_3', 'O001', 'P_SONY_WHXM6', 2, 2999.00);

INSERT INTO Orders (order_id, customer_id, order_date)
VALUES ('O002', 'C002', '2023-10-02');

INSERT INTO OrderDetail (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES
    ('O002_1', 'O002', 'P_SAMSUNG_ZFLIP5', 1, 8999.00),
    ('O002_2', 'O002', 'P_HUAWEI_MATEPAD2', 1, 5999.00),
    ('O002_3', 'O002', 'P_FUJI_XT6', 1, 13999.00);

INSERT INTO Orders (order_id, customer_id, order_date)
VALUES ('O003', 'C003', '2023-10-03');

INSERT INTO OrderDetail (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES
    ('O003_1', 'O003', 'P_SONY_A7M5', 1, 21999.00),
    ('O003_2', 'O003', 'P_SAMSUNG_QN95C', 1, 34999.00),
    ('O003_3', 'O003', 'P_DJI_POCKET3', 1, 3999.00);

INSERT INTO Orders (order_id, customer_id, order_date)
VALUES ('O004', 'C004', '2023-10-04');

INSERT INTO OrderDetail (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES
    ('O004_1', 'O004', 'P_HUAWEI_MATE60', 1, 13999.00),
    ('O004_2', 'O004', 'P_APPLE_VISIONPRO', 1, 25999.00),
    ('O004_3', 'O004', 'P_FUJI_INSTAX', 3, 599.00);

INSERT INTO Orders (order_id, customer_id, order_date)
VALUES ('O005', 'C005', '2023-10-05');

INSERT INTO OrderDetail (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES
    ('O005_1', 'O005', 'P_SAMSUNG_BUD2PRO', 2, 1299.00),
    ('O005_2', 'O005', 'P_SONY_PS5PRO', 1, 4999.00),
    ('O005_3', 'O005', 'P_HUAWEI_MATEVIEW', 1, 7999.00);

-- SQL Queries

-- Query customer purchase information
SELECT
    c.customer_id AS customer_id,
    c.contact_number AS contact_number,
    c.shipping_address AS shipping_address,
    o.order_id AS order_id,
    o.order_date AS order_date,
    p.product_name AS product_name,
    v.business_name AS vendor,
    od.quantity AS quantity,
    od.unit_price AS unit_price,
    od.quantity * od.unit_price AS total_price
FROM Customer c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN OrderDetail od ON o.order_id = od.order_id
JOIN Product p ON od.product_id = p.product_id
JOIN Vendor v ON p.vendor_id = v.vendor_id
ORDER BY c.customer_id, o.order_date;

-- Query all products for vendor 'V_DJI'
SELECT
    p.product_id AS product_id,
    p.product_name AS product_name,
    p.listed_price AS price,
    CONCAT(p.tag1, ', ', p.tag2, ', ', p.tag3) AS product_tags,
    p.inventory AS inventory,
    v.business_name AS vendor_name,
    v.geographical_presence AS region
FROM Product p
JOIN Vendor v ON p.vendor_id = v.vendor_id
WHERE p.vendor_id = 'V_DJI'
ORDER BY p.product_id;