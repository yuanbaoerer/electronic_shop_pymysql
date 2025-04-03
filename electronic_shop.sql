-- 检查数据库是否存在，若存在则删除
DROP DATABASE IF EXISTS electronics_shop;

-- 创建数据库
CREATE DATABASE electronics_shop 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- 使用数据库
USE electronics_shop;

-- 检查供应商表是否存在，若存在则删除
DROP TABLE IF EXISTS Vendor;
-- 供应商表（移除静态评分字段）
CREATE TABLE Vendor (
    vendor_id VARCHAR(20) PRIMARY KEY,
    business_name VARCHAR(100) NOT NULL,
    geographical_presence VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 检查客户表是否存在，若存在则删除
DROP TABLE IF EXISTS Customer;
-- 客户表
CREATE TABLE Customer (
    customer_id VARCHAR(20) PRIMARY KEY,
    contact_number VARCHAR(15) NOT NULL,
    shipping_address VARCHAR(200),
    shipping_state VARCHAR(50) DEFAULT '未发货'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 检查产品表是否存在，若存在则删除
DROP TABLE IF EXISTS Product;
-- 产品表（最多3个标签）
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

-- 检查订单表是否存在，若存在则删除
DROP TABLE IF EXISTS Orders;
-- 订单表（状态默认为待处理）
CREATE TABLE Orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    order_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT '待处理',
    tracking_number VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 检查订单详情表是否存在，若存在则删除
DROP TABLE IF EXISTS OrderDetail;
-- 订单详情表（添加评分字段）
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

-- 检查供应商评分视图是否存在，若存在则删除
DROP VIEW IF EXISTS VendorScores;
-- 供应商评分视图（动态计算平均分）
-- 更新视图 VendorScores
CREATE OR REPLACE VIEW VendorScores AS
SELECT 
    v.vendor_id,
    v.business_name,
    ROUND(AVG(od.rating), 1) AS feedback_score
FROM Vendor v
LEFT JOIN Product p ON v.vendor_id = p.vendor_id
LEFT JOIN OrderDetail od ON p.product_id = od.product_id AND od.rating IS NOT NULL
GROUP BY v.vendor_id;

-- 插入初始供应商数据
INSERT INTO Vendor (vendor_id, business_name, geographical_presence)
VALUES 
    ('V_DJI', '大疆', '中国'),
    ('V_SAMSUNG', '三星', '韩国'),
    ('V_SONY', '索尼', '日本'),
    ('V_APPLE', '苹果', '美国'),
    ('V_HUAWEI', '华为', '中国'),
    ('V_FUJIFILM', '富士', '日本');

-- 插入示例产品
-- ------------------------- 大疆（V_DJI）5个产品 -------------------------
INSERT INTO Product (product_id, vendor_id, product_name, listed_price, tag1, tag2, tag3, inventory)
VALUES
    ('P_DJI_MAVIC4', 'V_DJI', '大疆Mavic 4 Pro无人机', 14999.00, '无人机', '8K', '专业级', 40),
    ('P_DJI_MINI4', 'V_DJI', '大疆Mini 4 Pro无人机', 5499.00, '便携', '轻量', '智能跟随', 120),
    ('P_DJI_RS4', 'V_DJI', '大疆RS 4云台稳定器', 3599.00, '稳定器', '影视', '无线控制', 60),
    ('P_DJI_POCKET3', 'V_DJI', '大疆Pocket 3手持相机', 3999.00, 'Vlog', '4K', '防抖', 150),
    ('P_DJI_AIR3', 'V_DJI', '大疆Air 3航拍无人机', 8999.00, '双摄', '长续航', '避障', 80);

-- ------------------------- 三星（V_SAMSUNG）5个产品 -------------------------
INSERT INTO Product (product_id, vendor_id, product_name, listed_price, tag1, tag2, tag3, inventory)
VALUES
    ('P_SAMSUNG_S24', 'V_SAMSUNG', '三星Galaxy S24 Ultra', 9999.00, '手机', '5G', 'AI摄影', 180),
    ('P_SAMSUNG_ZFLIP5', 'V_SAMSUNG', '三星Galaxy Z Flip5', 8999.00, '折叠屏', '便携', '时尚', 90),
    ('P_SAMSUNG_QN95C', 'V_SAMSUNG', '三星Neo QLED 8K电视', 34999.00, '电视', '8K', 'Mini LED', 25),
    ('P_SAMSUNG_BUD2PRO', 'V_SAMSUNG', '三星Buds2 Pro耳机', 1299.00, '降噪', '无线', 'Hi-Fi', 300),
    ('P_SAMSUNG_T9', 'V_SAMSUNG', '三星T9移动固态硬盘', 1299.00, '存储', '高速', '防摔', 150);

-- ------------------------- 索尼（V_SONY）5个产品 -------------------------
INSERT INTO Product (product_id, vendor_id, product_name, listed_price, tag1, tag2, tag3, inventory)
VALUES
    ('P_SONY_A7M5', 'V_SONY', '索尼A7M5全画幅相机', 21999.00, '相机', '8K', 'AI对焦', 25),
    ('P_SONY_WHXM6', 'V_SONY', '索尼WH-1000XM6耳机', 2999.00, '降噪', '无线', '长续航', 200),
    ('P_SONY_PS5PRO', 'V_SONY', '索尼PS5 Pro游戏主机', 4999.00, '游戏机', '4K', '光追', 50),
    ('P_SONY_A6700', 'V_SONY', '索尼A6700微单相机', 12999.00, 'APS-C', 'Vlog', '轻量', 70),
    ('P_SONY_X95L', 'V_SONY', '索尼X95L Mini LED电视', 18999.00, '电视', '4K', 'XR芯片', 35);

-- ------------------------- 苹果（V_APPLE）5个产品 -------------------------
INSERT INTO Product (product_id, vendor_id, product_name, listed_price, tag1, tag2, tag3, inventory)
VALUES
    ('P_APPLE_IPHONE15', 'V_APPLE', 'iPhone 15 Pro Max', 10999.00, '手机', '钛金属', 'A17芯片', 200),
    ('P_APPLE_VISIONPRO', 'V_APPLE', 'Apple Vision Pro头显', 25999.00, 'VR', '空间计算', '3D界面', 30),
    ('P_APPLE_MACBOOKAIR', 'V_APPLE', 'MacBook Air 15英寸', 12999.00, '轻薄', 'M2芯片', 'Retina', 100),
    ('P_APPLE_AIRPODS3', 'V_APPLE', 'AirPods 3代', 1399.00, '无线', '空间音频', '防水', 400),
    ('P_APPLE_IPTV', 'V_APPLE', 'Apple TV 4K', 1499.00, '流媒体', 'HDR', '游戏', 150);

-- ------------------------- 华为（V_HUAWEI）5个产品 -------------------------
INSERT INTO Product (product_id, vendor_id, product_name, listed_price, tag1, tag2, tag3, inventory)
VALUES
    ('P_HUAWEI_MATE60', 'V_HUAWEI', '华为Mate 60 RS', 13999.00, '手机', '卫星通信', '昆仑玻璃', 100),
    ('P_HUAWEI_MATEPAD2', 'V_HUAWEI', '华为MatePad Pro 13.2', 5999.00, '平板', 'OLED', '鸿蒙', 80),
    ('P_HUAWEI_WATCH4', 'V_HUAWEI', '华为Watch 4 Pro', 2699.00, '健康监测', 'eSIM', '钛合金', 120),
    ('P_HUAWEI_FREEBUDS3', 'V_HUAWEI', '华为FreeBuds Pro 3', 1499.00, '降噪', '空间音频', 'Hi-Res', 250),
    ('P_HUAWEI_MATEVIEW', 'V_HUAWEI', '华为MateView显示器', 7999.00, '4K', '触控', '无线投屏', 60);

-- ------------------------- 富士（V_FUJIFILM）5个产品 -------------------------
INSERT INTO Product (product_id, vendor_id, product_name, listed_price, tag1, tag2, tag3, inventory)
VALUES
    ('P_FUJI_XT6', 'V_FUJIFILM', '富士X-T6微单相机', 13999.00, '复古', 'APS-C', '胶片模拟', 40),
    ('P_FUJI_GFX100S', 'V_FUJIFILM', '富士GFX100S中画幅', 45999.00, '中画幅', '1亿像素', '防抖', 20),
    ('P_FUJI_INSTAX', 'V_FUJIFILM', '富士Instax Mini 12', 599.00, '拍立得', '便携', '即影即有', 300),
    ('P_FUJI_X100V', 'V_FUJIFILM', '富士X100V数码相机', 10999.00, '旁轴', '定焦', '复古', 50),
    ('P_FUJI_XS20', 'V_FUJIFILM', '富士X-S20 Vlog相机', 8999.00, 'Vlog', '轻量', '4K', 70);

 -- 插入5个客户状态默认为未发货
INSERT INTO Customer (customer_id, contact_number, shipping_address)
VALUES
    ('C001', '13800000001', '北京市海淀区中关村大街1号'),
    ('C002', '13800000002', '上海市浦东新区张江路100号'),
    ('C003', '13800000003', '广州市天河区珠江新城华强路8号'),
    ('C004', '13800000004', '深圳市南山区科技园科苑路10号'),
    ('C005', '13800000005', '杭州市西湖区文三路399号');

-- 订单记录
INSERT INTO Orders (order_id, customer_id, order_date) 
VALUES ('O001', 'C001', '2023-10-01');

-- 订单详情（大疆、苹果、索尼）
INSERT INTO OrderDetail (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES
    ('O001_1', 'O001', 'P_DJI_MAVIC4', 1, 14999.00),  -- 大疆无人机
    ('O001_2', 'O001', 'P_APPLE_IPHONE15', 1, 10999.00), -- 苹果手机
    ('O001_3', 'O001', 'P_SONY_WHXM6', 2, 2999.00);      -- 索尼耳机（购买2副）
-- 订单记录
INSERT INTO Orders (order_id, customer_id, order_date)
VALUES ('O002', 'C002', '2023-10-02');

-- 订单详情（三星、华为、富士）
INSERT INTO OrderDetail (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES
    ('O002_1', 'O002', 'P_SAMSUNG_ZFLIP5', 1, 8999.00),  -- 三星折叠手机
    ('O002_2', 'O002', 'P_HUAWEI_MATEPAD2', 1, 5999.00),  -- 华为平板
    ('O002_3', 'O002', 'P_FUJI_XT6', 1, 13999.00);        -- 富士相机
-- 订单记录
INSERT INTO Orders (order_id, customer_id, order_date)
VALUES ('O003', 'C003', '2023-10-03');

-- 订单详情（索尼、三星、大疆）
INSERT INTO OrderDetail (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES
    ('O003_1', 'O003', 'P_SONY_A7M5', 1, 21999.00),      -- 索尼全画幅相机
    ('O003_2', 'O003', 'P_SAMSUNG_QN95C', 1, 34999.00),    -- 三星8K电视
    ('O003_3', 'O003', 'P_DJI_POCKET3', 1, 3999.00);       -- 大疆手持相机
-- 订单记录
INSERT INTO Orders (order_id, customer_id, order_date)
VALUES ('O004', 'C004', '2023-10-04');

-- 订单详情（华为、苹果、富士）
INSERT INTO OrderDetail (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES
    ('O004_1', 'O004', 'P_HUAWEI_MATE60', 1, 13999.00),   -- 华为手机
    ('O004_2', 'O004', 'P_APPLE_VISIONPRO', 1, 25999.00),  -- 苹果VR头显
    ('O004_3', 'O004', 'P_FUJI_INSTAX', 3, 599.00);        -- 富士拍立得（购买3台）
-- 订单记录
INSERT INTO Orders (order_id, customer_id, order_date)
VALUES ('O005', 'C005', '2023-10-05');

-- 订单详情（三星、索尼、华为）
INSERT INTO OrderDetail (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES
    ('O005_1', 'O005', 'P_SAMSUNG_BUD2PRO', 2, 1299.00),  -- 三星耳机（购买2副）
    ('O005_2', 'O005', 'P_SONY_PS5PRO', 1, 4999.00),       -- 索尼游戏主机
    ('O005_3', 'O005', 'P_HUAWEI_MATEVIEW', 1, 7999.00);   -- 华为显示器

-- SQL 查询

-- 查询客户购买信息（含客户、订单、产品、供应商信息）
SELECT 
    c.customer_id AS 客户ID,
    c.contact_number AS 联系电话,
    c.shipping_address AS 配送地址,
    o.order_id AS 订单号,
    o.order_date AS 下单日期,
    p.product_name AS 产品名称,
    v.business_name AS 供应商,
    od.quantity AS 购买数量,
    od.unit_price AS 单价,
    od.quantity * od.unit_price AS 总价
FROM Customer c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN OrderDetail od ON o.order_id = od.order_id
JOIN Product p ON od.product_id = p.product_id
JOIN Vendor v ON p.vendor_id = v.vendor_id
ORDER BY c.customer_id, o.order_date;

-- 查询供应商ID为 'V_DJI' 的所有产品
SELECT 
    p.product_id AS 产品ID,
    p.product_name AS 产品名称,
    p.listed_price AS 价格,
    CONCAT(p.tag1, ', ', p.tag2, ', ', p.tag3) AS 产品标签,
    p.inventory AS 库存,
    v.business_name AS 供应商名称,
    v.geographical_presence AS 地区
FROM Product p
JOIN Vendor v ON p.vendor_id = v.vendor_id
WHERE p.vendor_id = 'V_DJI'  -- 替换为实际供应商ID
ORDER BY p.product_id;
    