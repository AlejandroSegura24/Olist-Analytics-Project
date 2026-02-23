/*
===============================================================================
ARCHIVO: 01_views.sql
DESCRIPCIÓN: Creación de vistas para simplificar el modelo de datos.
===============================================================================
*/

-- ============================================================================
-- 1. VISTA: v_orders_cleaned
-- Objetivo: Comparar el tiempo de entrega real vs el estimado con los pedidos entregados.
-- ============================================================================

CREATE OR REPLACE VIEW v_orders_cleaned AS -- Logistica y Entregas
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp AS order_date,
    order_delivered_customer_date AS delivery_date,
    -- Calculamos el tiempo de entrega en días (si existe la fecha)
    EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)) AS delivery_time_days,
    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 
        ELSE 0 
    END AS is_on_time
FROM orders o
WHERE order_status = 'delivered' 
  AND order_delivered_customer_date IS NOT NULL;

-- Verificación rápida de la vista creada
SELECT * FROM v_orders_cleaned 
WHERE is_on_time = 0
LIMIT 10;

-- ============================================================================
-- 2. VISTA: v_order_summary
-- Objetivo: Consolidar el detalle de cada venta con su categoría, cliente y lugar.
-- ============================================================================

CREATE OR REPLACE VIEW v_order_summary AS  -- Resumen Ventas
SELECT
    oi.order_id,
    p.product_id,
    o.order_date,
    COALESCE(t.category_name_english, p.product_category_name, 'Uncategorized') AS category_name,
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
SELECT * FROM v_order_summary LIMIT 20;

-- ============================================================================
-- 3. VISTA: v_customer_satisfaction
-- Objetivo: Analizar la relación entre el puntaje de reseña y los productos.
-- ============================================================================

CREATE OR REPLACE VIEW v_customer_satisfaction AS -- Satisfaccion (reviews)
SELECT
    r.review_id,
    r.order_id,
    r.review_score,
    r.review_creation_date AS date_of_review,
    c.customer_state
FROM reviews r
JOIN orders o ON r.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id;

-- Verificación rápida de la vista creada
SELECT * FROM v_customer_satisfaction LIMIT 10;

-- ============================================================================
-- 4. VISTA: v_order_finance_details
-- Objetivo: Separar el valor real de la venta (precio + envio) de los intereses.
-- ============================================================================

CREATE OR REPLACE VIEW v_order_finance_details AS -- Finanzas y Cuotas
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
SELECT * FROM v_order_finance_details LIMIT 10;

-- ============================================================================
-- 5. VISTA: v_clean_geolocation_enriched
-- Objetivo: Crear un catálogo maestro de geolocalización que elimine duplicados 
-- e impute automáticamente los códigos postales faltantes.
-- ============================================================================

CREATE OR REPLACE VIEW v_clean_geolocation_enriched AS -- Ubicaciones por Ciudad

-- 1. Agrupación de la tabla original para tener un único punto por cada Zip Code
WITH geo_base AS (
    SELECT
        g.geolocation_zip_code_prefix,
        AVG(g.geolocation_lat) AS latitude,
        AVG(g.geolocation_lng) AS longitude,
        INITCAP(MAX(g.geolocation_city)) AS city,
        UPPER(MAX(g.geolocation_state)) AS state
    FROM geolocation g
    GROUP BY g.geolocation_zip_code_prefix
),

-- 2. Calculamos el centroide o punto medio de cada Estado
-- Esto servirá como para los códigos postales que no tienen coordenadas
state_centroid AS (
    SELECT
        state,
        AVG(latitude) AS state_latitude,
        AVG(longitude) AS state_longitude
    FROM geo_base
    GROUP BY state
),

-- 3. Identificamos los Zip Codes que aparecen en las ventas pero no en el catálogo de geografía
missing_zip AS (
    SELECT DISTINCT
        c.customer_zip_code_prefix AS geolocation_zip_code_prefix,
        INITCAP(c.customer_city) AS city,
        UPPER(c.customer_state) AS state
    FROM customers c
    LEFT JOIN geo_base gb
        ON gb.geolocation_zip_code_prefix = c.customer_zip_code_prefix
    WHERE c.customer_zip_code_prefix IS NOT NULL
      AND gb.geolocation_zip_code_prefix IS NULL
)

-- 4. Combinamos ambos universos (Datos originales + Datos rescatados)
-- SELECT A: Los registros que ya estaban en la base geográfica
SELECT
    gb.geolocation_zip_code_prefix AS zip_code_id,
    gb.latitude,
    gb.longitude,
    gb.city,
    gb.state
FROM geo_base gb

UNION ALL

-- SELECT B: Los 278 registros rescatados, asignándoles el centro de su estado
SELECT
    mz.geolocation_zip_code_prefix AS zip_code_id,
    sc.state_latitude AS latitude,
    sc.state_longitude AS longitude,
    mz.city,
    mz.state
FROM missing_zip mz
LEFT JOIN state_centroid sc
    ON sc.state = mz.state;

-- Verificación rápida de la vista creada
SELECT * FROM v_clean_geolocation_enriched LIMIT 10;

-- ============================================================================
-- 6. VISTA: fact_orders_bridge
-- Objetivo: Vista principal para union de las demas vistas
-- ============================================================================
CREATE OR REPLACE VIEW fact_orders_bridge AS -- Puente Ordenes
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_zip_code_prefix AS zip_code_id,
    o.order_status,
    o.order_purchase_timestamp AS order_date
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id;

--  Verificación rápida de la vista creada
SELECT COUNT(*) FROM fact_orders_bridge LIMIT 5