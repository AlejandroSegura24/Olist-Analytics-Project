/*
===============================================================================
ARCHIVO: 02_views.sql
DESCRIPCIÓN: Creación de vistas para simplificar el modelo de datos.
===============================================================================
*/

-- ----------------------------------------------------------------------------
-- 1. VISTA: v_order_summary
-- Objetivo: Consolidar el detalle de cada venta con su categoría, cliente y lugar.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_order_summary AS
SELECT
    oi.order_id,
    o.order_purchase_timestamp as order_date,
    p.product_id,
    COALESCE(t.category_name_english, p.product_category_name) AS category_name,
    oi.price,
    oi.freight_value,
    c.customer_state,
    s.seller_state
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN sellers s ON oi.seller_id = s.seller_id
LEFT JOIN name_category t ON p.product_category_name = t.category_name;

-- Verificación rápida de la vista creada
SELECT * FROM v_order_summary LIMIT 5;

-- ----------------------------------------------------------------------------
-- 2. VISTA: v_customer_satisfaction
-- Objetivo: Analizar la relación entre el puntaje de reseña y los productos.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_customer_satisfaction AS
SELECT 
    r.review_id,
    r.order_id,
    r.review_score,
    COALESCE(t.category_name_english, p.product_category_name) AS product_category,
    r.review_creation_date AS date_of_review
FROM reviews r
JOIN order_items oi ON r.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN name_category t ON p.product_category_name = t.category_name
ORDER BY r.review_score DESC;

-- Verificación rápida de la vista creada
SELECT * FROM v_customer_satisfaction LIMIT 5;

-- ----------------------------------------------------------------------------
-- 3. VISTA: v_logistics_efficiency
-- Objetivo: Comparar el tiempo de entrega real vs el estimado.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_logistics_efficiency AS
SELECT 
    order_id,
    customer_id,
    order_purchase_timestamp AS purchase_date,
    order_delivered_customer_date AS delivered_date,
    order_estimated_delivery_date AS estimated_delivery_date,
    -- Días de diferencia (Valores positivos = entrega a tiempo, Negativos = retraso)
    EXTRACT(DAY FROM (order_estimated_delivery_date - order_delivered_customer_date)) AS days_advantage
FROM orders
WHERE order_status = 'delivered' 
  AND order_delivered_customer_date IS NOT NULL;

-- Verificación rápida de la vista creada
SELECT * FROM v_logistics_efficiency LIMIT 5;

-- ----------------------------------------------------------------------------
-- 4. VISTA: v_clean_geolocation
-- Objetivo: Limpiar la tabla de geolocalización para tener un solo punto por código postal.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_clean_geolocation AS
SELECT 
    geolocation_zip_code_prefix,
    AVG(geolocation_lat) AS latitude,
    AVG(geolocation_lng) AS longitude,
    INITCAP(MAX(geolocation_city)) AS city,
    UPPER(MAX(geolocation_state)) AS state
FROM geolocation
GROUP BY geolocation_zip_code_prefix;

-- Verificación rápida de la vista creada
SELECT * FROM v_clean_geolocation LIMIT 10;