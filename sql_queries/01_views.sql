/*
===============================================================================
ARCHIVO: 01_views.sql
DESCRIPCIÓN: Creación de vistas para simplificar el modelo de datos.
===============================================================================
*/

-- ----------------------------------------------------------------------------
-- 1. VISTA: v_orders_cleaned
-- Objetivo: Comparar el tiempo de entrega real vs el estimado con los pedidos entregados.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_orders_cleaned AS
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp AS order_date,
    order_delivered_customer_date AS delivery_date,
    -- Calculamos el tiempo de entrega en días (si existe la fecha)
    EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)) AS delivery_time_days
FROM orders
WHERE order_status = 'delivered' 
  AND order_delivered_customer_date IS NOT NULL;

-- Verificación rápida de la vista creada
SELECT * FROM v_orders_cleaned LIMIT 10;

-- ----------------------------------------------------------------------------
-- 2. VISTA: v_order_summary
-- Objetivo: Consolidar el detalle de cada venta con su categoría, cliente y lugar.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_order_summary AS
SELECT
    oi.order_id,
    p.product_id,
    o.order_date,
    COALESCE(t.category_name_english, p.product_category_name) AS category_name,
    oi.price,
    oi.freight_value,
    c.customer_state,
    s.seller_state
FROM order_items oi
JOIN v_orders_cleaned o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN sellers s ON oi.seller_id = s.seller_id
LEFT JOIN name_category t ON p.product_category_name = t.category_name;

-- Verificación rápida de la vista creada
SELECT * FROM v_order_summary LIMIT 10;

-- ----------------------------------------------------------------------------
-- 3. VISTA: v_customer_satisfaction
-- Objetivo: Analizar la relación entre el puntaje de reseña y los productos.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_customer_satisfaction AS
SELECT 
    r.review_id,
    r.order_id,
    r.review_score,
    COALESCE(t.category_name_english, p.product_category_name) AS category_name,
    r.review_creation_date AS date_of_review,
    c.customer_state
FROM reviews r
JOIN orders o ON r.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON r.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN name_category t ON p.product_category_name = t.category_name
ORDER BY r.review_score DESC;

-- Verificación rápida de la vista creada
SELECT * FROM v_customer_satisfaction LIMIT 10;

-- ----------------------------------------------------------------------------
-- 4. VISTA: v_order_finance_details
-- Objetivo: Separar el valor real de la venta (precio + envio) de los intereses.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_order_finance_details AS
WITH order_totals AS (
    SELECT 
        order_id,
        SUM(price) AS items_value,
        SUM(freight_value) AS shipping_value,
        SUM(price + freight_value) AS expected_order_total
    FROM order_items
    GROUP BY order_id
),
payment_totals AS (
    SELECT 
        order_id,
        SUM(payment_value) AS total_paid,
        MAX(payment_installments) AS max_installments
    FROM order_payments
    GROUP BY order_id
)
SELECT 
    ot.order_id,
    ot.items_value,
    ot.shipping_value,
    ot.expected_order_total,
    pt.total_paid,
    pt.max_installments,
    CASE 
        WHEN pt.total_paid > ot.expected_order_total THEN ROUND((pt.total_paid - ot.expected_order_total)::numeric, 2)
        ELSE 0 
    END AS interests
FROM order_totals ot
JOIN payment_totals pt ON ot.order_id = pt.order_id;

-- Verificación rápida de la vista creada
SELECT * FROM v_order_finance_details 
WHERE interests > 0
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 5. VISTA: v_clean_geolocation
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