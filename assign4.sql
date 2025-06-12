-- 1. Build your own operational database for a business use case of your choice

CREATE DATABASE practical_assignment4;
USE practical_assignment4;

CREATE TABLE categories (
    category_id BIGINT PRIMARY KEY,
    category_name VARCHAR(255) UNIQUE NOT NULL
);
CREATE TABLE products (
    product_id BIGINT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL UNIQUE,
    category_id BIGINT NOT NULL,
    price BIGINT NOT NULL CHECK (price >= 0),
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);
CREATE TABLE customers (
    customer_id BIGINT PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL UNIQUE
);
CREATE TABLE suppliers (
    supplier_id BIGINT PRIMARY KEY,
    supplier_name VARCHAR(255) NOT NULL UNIQUE,
    category_id BIGINT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);
CREATE TABLE orders (
    order_id BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    order_date DATE NOT NULL CHECK (order_date <= CURRENT_DATE),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);
CREATE TABLE order_items (
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity BIGINT NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 4. Use indexes for optimization (insert ~500,000 rows into at least one or more key tables)

CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);

-- 5. Add comments on tables and their columns for documentation

ALTER TABLE customers COMMENT = 'таблиця з інформацією про клієнтів';
ALTER TABLE customers MODIFY customer_id BIGINT COMMENT 'ідентифікатор клієнта';
ALTER TABLE customers MODIFY customer_name varchar(255) COMMENT 'ім’я  клієнта';

ALTER TABLE categories COMMENT = 'категорії товарів';
ALTER TABLE categories MODIFY category_id BIGINT COMMENT 'ідентифікатор категорії';
ALTER TABLE categories  MODIFY category_name VARCHAR(255) COMMENT 'назва категорії';

ALTER TABLE suppliers COMMENT = 'інформація про постачальників';
ALTER TABLE suppliers MODIFY supplier_id BIGINT COMMENT 'ідентифікатор постачальника';
ALTER TABLE suppliers MODIFY supplier_name VARCHAR(255) COMMENT 'ім’я постачальника';
ALTER TABLE suppliers MODIFY category_id BIGINT COMMENT 'категорія, яку постачає даний постачальник';

ALTER TABLE products COMMENT = 'інформація про товари';
ALTER TABLE products MODIFY product_id BIGINT COMMENT 'ідентифікатор товару';
ALTER TABLE products MODIFY product_name VARCHAR(255) COMMENT 'назва товару';
ALTER TABLE products MODIFY category_id BIGINT COMMENT 'категорія, до якої належить товар';
ALTER TABLE products MODIFY price BIGINT COMMENT 'ціна одиниці товару (в гривнях)';

ALTER TABLE orders COMMENT = 'інформація про замовлення';
ALTER TABLE orders MODIFY order_id BIGINT COMMENT 'ідентифікатор замовлення';
ALTER TABLE orders MODIFY customer_id BIGINT COMMENT 'замовник';
ALTER TABLE orders MODIFY supplier_id BIGINT COMMENT 'постачальник';
ALTER TABLE orders MODIFY order_date DATE COMMENT 'дата оформлення замовлення';

ALTER TABLE order_items COMMENT = 'позиції в замовленні';
ALTER TABLE order_items MODIFY order_id BIGINT COMMENT 'ідентифікатор замовлення';
ALTER TABLE order_items MODIFY product_id BIGINT COMMENT 'ідентифікатор товару';
ALTER TABLE order_items MODIFY quantity BIGINT COMMENT 'кількість одиниць замовленого товару';

-- *1. Create at least 3 different users with different privileges

CREATE USER 'admin'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON practical_assignment4.* TO 'admin'@'localhost';

CREATE USER 'orders_manager'@'localhost' IDENTIFIED BY 'password';
GRANT SELECT, INSERT, UPDATE, DELETE ON practical_assignment4.orders TO 'orders_manager'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON practical_assignment4.order_items TO 'orders_manager'@'localhost';

CREATE USER 'accountant'@'localhost' IDENTIFIED BY 'password';
GRANT SELECT ON practical_assignment4.orders TO 'accountant'@'localhost';
GRANT SELECT ON practical_assignment4.suppliers TO 'accountant'@'localhost';

-- *2. Create at least 1 view

CREATE VIEW view_of_orders AS
SELECT
    o.order_id,
    c.customer_name,
    p.product_name,
    oi.quantity,
    p.price,
    (oi.quantity * p.price) AS total_price
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;

select * from view_of_orders;

-- *3. Create a stored procedure

DELIMITER //
CREATE PROCEDURE create_order(
    IN cid BIGINT,
    IN pid BIGINT,
    IN qty INT
)
BEGIN
  INSERT INTO orders (customer_id, supplier_id, order_date)
  SELECT cid, s.supplier_id, CURDATE()
  FROM products p
  JOIN suppliers s ON p.category_id = s.category_id
  WHERE p.product_id = pid
  LIMIT 1;

  INSERT INTO order_items (order_id, product_id, quantity)
  SELECT o.order_id, pid, qty
  FROM orders o
  WHERE o.customer_id = cid
  ORDER BY o.order_id DESC
  LIMIT 1;
END; // 
DELIMITER ;

CALL create_order(1, 2, 3);
select * from orders where customer_id = 1 and order_date = curdate();
select * from order_items where product_id = 2 and quantity = 3;


-- *4.	Create a trigger or function

CREATE TRIGGER product_price_error BEFORE INSERT ON products FOR EACH ROW
    IF NEW.price < 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ціна продукту занадто мала';
    END IF;
SHOW TRIGGERS LIKE 'products';

INSERT INTO products (product_id, product_name, category_id, price)
VALUES (2001, 'Car', 1, 1);
