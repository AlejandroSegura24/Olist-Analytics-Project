/*
===============================================================================
PROYECTO: Olist-Analytics-Project (Brasil)
DESCRIPCIÓN: Creación del esquema de base de datos e ingesta de datos.
AUTOR: Alejandro Segura
FECHA: 2026-02-06
===============================================================================
*/

-- Creación de la base de datos principal para el proyecto e-commerce
CREATE DATABASE olist_analytics
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1;

-- NOTA: Después de ejecutar esto, recuerda desconectarte de 'postgres' 
-- y conectarte a 'olist_analytics' para ejecutar el script de las tablas (01_schema_and_load.sql).

-- ----------------------------------------------------------------------------
-- 1. TABLAS INDEPENDIENTES
-- Estas tablas se crean primero porque no dependen de ninguna otra.
-- ----------------------------------------------------------------------------

-- Información maestra de clientes
CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(50) PRIMARY KEY, -- ID único por pedido del cliente
    customer_unique_id VARCHAR(50),      -- ID único histórico del cliente
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

-- Catálogo de productos
CREATE TABLE IF NOT EXISTS products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- Información de vendedores
CREATE TABLE IF NOT EXISTS sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);

-- Diccionario de traducción de categorías (Portugués -> Inglés)
CREATE TABLE IF NOT EXISTS name_category (
    category_name VARCHAR(100) PRIMARY KEY,
    category_name_english VARCHAR(100)
);

-- Datos de geolocalización por código postal
CREATE TABLE IF NOT EXISTS geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(2)
);

-- ----------------------------------------------------------------------------
-- 2. TABLAS DEPENDIENTES
-- Se crean siguiendo el orden de integridad referencial.
-- ----------------------------------------------------------------------------

-- Cabecera de pedidos (Depende de Customers)
CREATE TABLE IF NOT EXISTS orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Detalle de productos por pedido
-- Se usa PK Compuesta porque un pedido puede tener múltiples productos.
CREATE TABLE IF NOT EXISTS order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10, 2),  -- Usamos DECIMAL para precisión monetaria
    freight_value DECIMAL(10, 2),
    PRIMARY KEY (order_item_id, order_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

-- Métodos de pago por pedido
CREATE TABLE IF NOT EXISTS order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10, 2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Reseñas de clientes por pedido
CREATE TABLE IF NOT EXISTS reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    PRIMARY KEY (review_id, order_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- ----------------------------------------------------------------------------
-- 3. INGESTA DE DATOS
-- INSTRUCCIONES: Asegúrate de que los archivos CSV estén en una ruta accesible para el servidor de PostgreSQL.
-- ----------------------------------------------------------------------------

COPY customers FROM 'C:\datos\data\olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf8');
COPY products FROM 'C:\datos\data\olist_products_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf8');
COPY sellers FROM 'C:\datos\data\olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf8');
COPY geolocation FROM 'C:\datos\data\olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf8');
COPY name_category FROM 'C:\datos\data\product_category_name_translation.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf8');
COPY orders FROM 'C:\datos\data\olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf8');
COPY order_items FROM 'C:\datos\data\olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf8');
COPY order_payments FROM 'C:\datos\data\olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf8');
COPY reviews FROM 'C:\datos\data\olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'utf8');

-- Verificación rápida de datos cargados
SELECT * FROM reviews LIMIT 5;