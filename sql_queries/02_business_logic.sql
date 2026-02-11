/*
===============================================================================
ARCHIVO: 02_business_logic.sql
DESCRIPCIÓN: Consultas de alto nivel para extraer insights de negocio, 
             uniones complejas y métricas de rendimiento orientadas a KPIs.
===============================================================================
*/

-- 1. ANALISIS GEOGRÁFICO: Concentración de Ingresos y Market Share por Estado
-- Objetivo: Identificar los mercados clave y el peso relativo de cada región en la facturación total.

SELECT customer_state,
        COUNT(DISTINCT order_id) AS order_volume,
        ROUND(SUM(price)::numeric, 2)AS total_income,
        ROUND(AVG(price)::numeric, 2) AS avg_price,
        ROUND((SUM(price)::numeric / SUM(SUM(price)) OVER()) * 100, 2) AS market_share_percent
FROM v_order_summary
GROUP BY customer_state
HAVING COUNT(DISTINCT order_id) > 100
ORDER BY order_volume DESC;

-- 2. ECONOMÍA DEL CRÉDITO: Impacto Real de Intereses y Capacidad de Pago Mensual
-- Objetivo: Analizar el costo del financiamiento exclusivamente para clientes que generaron intereses, 
-- calculando el "ticket" mensual para entender el flujo de caja del consumidor.

SELECT 
    max_installments,
    COUNT(*) AS total_buyers_with_interest,
    ROUND((SUM(total_paid) - SUM(interests))::numeric, 2) AS total_base_income,
    ROUND(SUM(interests)::numeric, 2) AS total_interest_income,
    ROUND(AVG(total_paid / max_installments)::numeric, 2) AS avg_monthly_installment,
    ROUND(AVG(interests / max_installments)::numeric, 2) AS avg_interests_installment,
    ROUND((SUM(interests) / SUM(total_paid) * 100 / max_installments)::numeric, 2) AS interest_percent_per_installment
FROM v_order_finance_details
WHERE interests > 0
GROUP BY max_installments
ORDER BY max_installments ASC;

-- 3. NUDO CRÍTICO LOGÍSTICO: Correlación entre Tiempo de Entrega y Satisfacción del Cliente
-- Objetivo: Determinar los rangos de tolerancia del cliente y el impacto directo de los retrasos 
-- en la calificación final del servicio.

SELECT 
    CASE 
        WHEN delivery_time_days <= 7 THEN '01. Rápido (0-7 días)'
        WHEN delivery_time_days <= 15 THEN '02. Normal (8-15 días)'
        WHEN delivery_time_days <= 30 THEN '03. Lento (16-30 días)'
        ELSE '04. Crítico (+30 días)'
    END AS delivery_performance,
    COUNT(*) AS total_orders,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score
FROM v_orders_cleaned
INNER JOIN v_customer_satisfaction 
    ON v_orders_cleaned.order_id = v_customer_satisfaction.order_id
GROUP BY 1
ORDER BY 1;

-- 4. RANKING DE RENTABILIDAD: KPI por Categoría de Producto y Salud Operativa
-- Objetivo: Identificar el Top 10 de categorías con mayores ingresos, cruzando datos de ventas, 
-- eficiencia logística y satisfacción promedio.

SELECT 
    COALESCE(t.category_name_english, p.product_category_name) AS category_name,
    COUNT(oi.order_id) AS total_sales,
    ROUND(SUM(oi.price)::numeric, 2) AS total_income,
    ROUND(AVG(voc.delivery_time_days)::numeric, 1) AS avg_delivery_days,
    ROUND(AVG(vcs.review_score)::numeric, 2) AS avg_satisfaction
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN v_orders_cleaned voc ON oi.order_id = voc.order_id
JOIN v_customer_satisfaction vcs ON oi.order_id = vcs.order_id
LEFT JOIN name_category t ON p.product_category_name = t.category_name
WHERE p.product_category_name IS NOT NULL
GROUP BY COALESCE(t.category_name_english, p.product_category_name)
ORDER BY total_income DESC
LIMIT 10;