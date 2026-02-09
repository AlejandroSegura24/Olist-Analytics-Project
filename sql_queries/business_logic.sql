/*
===============================================================================
ARCHIVO: business_logic.sql
DESCRIPCIÓN: Consultas de alto nivel para extraer insights de negocio, 
             uniones complejas y métricas de rendimiento.
===============================================================================
*/

-- 1. Análisis de Concentración de Ingresos por Estado
-- ¿Dónde están nuestros clientes más valiosos?
SELECT 
    c.customer_state, 
    COUNT(DISTINCT o.order_id) AS volumen_pedidos,
    ROUND(SUM(oi.price)::numeric, 2) AS ingresos_totales
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY ingresos_totales DESC;

-- 2. Preferencias de Métodos de Pago y Cuotas (Installments)
-- Analizamos si los clientes prefieren pagar a plazos o en un solo pago.
SELECT 
    payment_type,
    ROUND(AVG(payment_installments), 1) AS promedio_cuotas,
    COUNT(*) AS total_transacciones,
    ROUND(SUM(payment_value)::numeric, 2) AS total_pagado
FROM order_payments
GROUP BY payment_type
ORDER BY total_pagado DESC;

-- 3. Tiempos de Respuesta de Vendedores
-- Medimos cuántos días tarda el vendedor en entregar el producto al transportista.
SELECT 
    s.seller_id,
    s.seller_city,
    ROUND(AVG(EXTRACT(DAY FROM (o.order_delivered_carrier_date - o.order_purchase_timestamp)))::numeric, 2) AS dias_promedio_envio
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
WHERE o.order_delivered_carrier_date IS NOT NULL
GROUP BY s.seller_id, s.seller_city
HAVING COUNT(o.order_id) > 10
ORDER BY dias_promedio_envio ASC
LIMIT 10;