/*
===============================================================================
ARCHIVO: 02_pre_processing_analysis.sql
DESCRIPCIÓN: Consultas iniciales para validación de calidad de datos, vista
             de valores atípicos (outliers) o nulos.
===============================================================================
*/

-- 1. Verificación de valores nulos en fechas críticas de entrega

SELECT 
    order_status, 
    COUNT(*) AS total_volume,
    COUNT(order_delivered_customer_date) AS records_with_date
FROM orders
GROUP BY order_status
ORDER BY total_volume ASC;

-- 2. Detección de duplicados en la tabla Geolocation

SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS duplicated_records,
    COUNT(DISTINCT (geolocation_lat, geolocation_lng)) AS unique_coordinates
FROM geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1
ORDER BY duplicated_records DESC
LIMIT 15;

-- 3. Auditoría de integridad financiera: Análisis de diferencias y cuotas
-------------------------------------------------------------------------------
-- FASE A: Identificación de Diferencias (El "Problema")
-- Objetivo: Listar los pedidos donde el monto pagado no coincide con el carrito.
-------------------------------------------------------------------------------

WITH financial_check AS (
    SELECT 
        oi.order_id,
        SUM(oi.price + oi.freight_value) AS expected_total,
        (SELECT SUM(payment_value) FROM order_payments op WHERE op.order_id = oi.order_id) AS actual_payment
    FROM order_items oi
    GROUP BY oi.order_id
)
SELECT 
    order_id,
    expected_total,
    actual_payment,
    ABS(expected_total - actual_payment) AS diff_amount
FROM financial_check
WHERE ABS(expected_total - actual_payment) > 0.1
ORDER BY diff_amount DESC
LIMIT 20;

-------------------------------------------------------------------------------
-- FASE B: Validación de Hipótesis (La "Explicación": Intereses por Cuotas)
-- Objetivo: Demostrar que el excedente crece proporcionalmente a las cuotas.
-------------------------------------------------------------------------------

WITH order_comparison AS (
    SELECT 
        oi.order_id,
        SUM(oi.price) AS items_subtotal,
        SUM(oi.freight_value) AS total_shipping,
        SUM(oi.price + oi.freight_value) AS expected_order_value,
        op.payment_value AS actual_amount_paid,
        op.payment_installments AS installments_count
    FROM order_items oi
    JOIN order_payments op ON oi.order_id = op.order_id
    GROUP BY oi.order_id, op.payment_value, op.payment_installments
)
SELECT 
    order_id,
    expected_order_value,
    actual_amount_paid,
    installments_count,
    -- Calculamos el interés total
    ROUND((actual_amount_paid - expected_order_value)::numeric, 2) AS total_interest_paid,
    -- Calculamos cuánto interés hubo en cada cuota
    CASE 
        WHEN installments_count > 0 THEN 
            ROUND(((actual_amount_paid - expected_order_value) / installments_count)::numeric, 2)
        ELSE 0 
    END AS interest_per_installment
FROM order_comparison
WHERE actual_amount_paid > expected_order_value
ORDER BY total_interest_paid DESC
LIMIT 10;