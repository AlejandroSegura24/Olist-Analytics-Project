/*
===============================================================================
ARCHIVO: exploratory.sql
DESCRIPCIÓN: Consultas iniciales para validación de calidad de datos y 
             limpieza de valores atípicos (outliers) o nulos.
===============================================================================
*/

-- 1. Verificación de valores nulos en fechas críticas de entrega
SELECT 
    order_status, 
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS date_nulls
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- 2. Detección de duplicados en la tabla Geolocation
SELECT 
    geolocation_zip_code_prefix, 
    COUNT(*) as records_by_code
FROM geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1
ORDER BY records_by_code DESC
LIMIT 10;

-- 3. Análisis de valores monetarios extremos
SELECT 
    MIN(price) AS price_min,
    MAX(price) AS price_max,
    AVG(price) AS price_average,
    STDDEV(price) AS standard_deviation
FROM order_items;