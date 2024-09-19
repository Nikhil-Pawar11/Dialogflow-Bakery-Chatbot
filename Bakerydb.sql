-- Create a new database for the bakery chatbot project
CREATE DATABASE IF NOT EXISTS bakery_chatbot;
USE bakery_chatbot;

-- Step 1: Disable foreign key checks for table creation
SET foreign_key_checks = 0;

-- Drop existing tables if they exist to avoid conflicts
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS food_items;
DROP TABLE IF EXISTS order_tracking;

-- Step 2: Create the food_items table
CREATE TABLE food_items (
  item_id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) DEFAULT NULL,
  price DECIMAL(10,2) DEFAULT NULL,
  PRIMARY KEY (item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Step 3: Create the order_tracking table
CREATE TABLE order_tracking (
  order_id INT NOT NULL AUTO_INCREMENT,
  status VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Step 4: Create the orders table with foreign key relationships
CREATE TABLE orders (
  order_id INT NOT NULL,
  item_id INT NOT NULL,
  quantity INT DEFAULT NULL,
  total_price DECIMAL(10,2) DEFAULT NULL,
  PRIMARY KEY (order_id, item_id),
  KEY orders_ibfk_1 (item_id),
  CONSTRAINT orders_ibfk_1 FOREIGN KEY (item_id) REFERENCES food_items (item_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Step 5: Insert data into the food_items table
INSERT INTO food_items (item_id, name, price) VALUES
(1, 'Black Forest Cake', 30.00),
(2, 'Cheesecake', 28.00),
(3, 'Lemon Drizzle Cake', 25.00),
(4, 'Red Velvet Cake', 32.00),
(5, 'Carrot Cake', 26.00),
(6, 'Chocolate Eclair', 18.00),
(7, 'Fruit Tart', 20.00),
(8, 'Cupcake', 15.00),
(9, 'Brownie', 17.00);

-- Step 6: Insert data into order_tracking table
INSERT INTO order_tracking (order_id, status) VALUES
(1, 'delivered'),
(2, 'in transit');

-- Step 7: Insert data into orders table
INSERT INTO orders (order_id, item_id, quantity, total_price) VALUES
(1, 1, 2, 60.00),
(1, 3, 1, 25.00),
(2, 4, 3, 96.00),
(2, 6, 2, 36.00),
(2, 8, 4, 60.00);

-- Step 8: Drop existing functions and procedures to avoid conflicts
DROP FUNCTION IF EXISTS get_price_for_item;
DROP FUNCTION IF EXISTS get_total_order_price;
DROP PROCEDURE IF EXISTS insert_order_item;

-- Step 9: Create the get_price_for_item function
DELIMITER ;;
CREATE DEFINER=root@localhost FUNCTION get_price_for_item(p_item_name VARCHAR(255)) RETURNS decimal(10,2)
    DETERMINISTIC
BEGIN
    DECLARE v_price DECIMAL(10, 2);
    
    -- Check if the item_name exists in the food_items table
    IF (SELECT COUNT(*) FROM food_items WHERE name = p_item_name) > 0 THEN
        -- Retrieve the price for the item
        SELECT price INTO v_price
        FROM food_items
        WHERE name = p_item_name;
        
        RETURN v_price;
    ELSE
        -- Invalid item_name, return -1
        RETURN -1;
    END IF;
END ;;
DELIMITER ;

-- Step 10: Create the get_total_order_price function
DELIMITER ;;
CREATE DEFINER=root@localhost FUNCTION get_total_order_price(p_order_id INT) RETURNS decimal(10,2)
    DETERMINISTIC
BEGIN
    DECLARE v_total_price DECIMAL(10, 2);
    
    -- Check if the order_id exists in the orders table
    IF (SELECT COUNT(*) FROM orders WHERE order_id = p_order_id) > 0 THEN
        -- Calculate the total price
        SELECT SUM(total_price) INTO v_total_price
        FROM orders
        WHERE order_id = p_order_id;
        
        RETURN v_total_price;
    ELSE
        -- Invalid order_id, return -1
        RETURN -1;
    END IF;
END ;;
DELIMITER ;

-- Step 11: Create the insert_order_item procedure
DELIMITER ;;
CREATE DEFINER=root@localhost PROCEDURE insert_order_item(
  IN p_food_item VARCHAR(255),
  IN p_quantity INT,
  IN p_order_id INT
)
BEGIN
    DECLARE v_item_id INT;
    DECLARE v_price DECIMAL(10, 2);
    DECLARE v_total_price DECIMAL(10, 2);

    -- Get the item_id and price for the food item
    SET v_item_id = (SELECT item_id FROM food_items WHERE name = p_food_item);
    SET v_price = (SELECT get_price_for_item(p_food_item));

    -- Calculate the total price for the order item
    SET v_total_price = v_price * p_quantity;

    -- Insert the order item into the orders table
    INSERT INTO orders (order_id, item_id, quantity, total_price)
    VALUES (p_order_id, v_item_id, p_quantity, v_total_price);
END ;;
DELIMITER ;

-- Step 12: Re-enable foreign key checks
SET foreign_key_checks = 1; 