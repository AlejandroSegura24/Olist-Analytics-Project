# 📂 Database Setup & Data Ingestion

Este módulo constituye el núcleo de datos del proyecto. Aquí se gestiona desde la creación de la infraestructura física y la ingesta de datos, hasta la validación de calidad y la creación de capas analíticas.

## 1) Contexto y Propósito
El objetivo de este script es transformar archivos planos (CSV) en una base de datos relacional robusta. En el contexto de Olist, esto es crítico porque:
* **Normalización:** Permite cruzar la información de clientes, vendedores y productos sin redundancias.
* **Trazabilidad:** Establece las reglas para entender el ciclo de vida de una orden, desde la compra hasta la reseña del cliente.

## 2) Fase 1: Creación e Ingesta (01_schema_and_load.sql) 🏗️

En esta etapa se define la estructura técnica del proyecto. Se priorizaron decisiones que garantizan la precisión y la escalabilidad:

* **Precisión Financiera:** Se utiliza el tipo de dato `DECIMAL(10,2)` para los campos de precio, flete y pagos. A diferencia del tipo `FLOAT`, este evita errores de redondeo acumulativos en cálculos de Revenue.
* **Trazabilidad Temporal:** Uso de `TIMESTAMP` para todos los hitos logísticos, permitiendo cálculos precisos de intervalos (SLA).
* **Eficiencia de Ingesta:** Se empleó el comando `COPY` de PostgreSQL para una carga masiva y eficiente de los archivos CSV originales en formato UTF-8.

### 1.1 Diagrama de Entidad-Relación (ERD) 🗺️

A continuación se presenta la arquitectura lógica de la base de datos de Olist, destacando las relaciones entre las 9 tablas principales:

![ERD Olist High Resolution](../assets/erd_diagram.png)
*Figura 1: Esquema relacional que muestra la integridad referencial y las claves compuestas.*

### 1.2 Diccionario de Datos Completo 📖

| Tabla | Tipo | Descripción |
| :--- | :--- | :--- |
| `customers` | Dimensión | Datos de clientes y ubicación. |
| `products` | Dimensión | Catálogo con dimensiones físicas de productos. |
| `sellers` | Dimensión | Información de los vendedores del marketplace. |
| `name_category`| Referencia | Traducción de categorías (Portugués -> Inglés). |
| `geolocation` | Referencia | Coordenadas geográficas por código postal. |
| `orders` | Hechos | Cabecera del pedido (Status y Timestamps). |
| `order_items` | Hechos | Detalle de productos, precios y fletes por pedido. |
| `order_payments`| Hechos | Transacciones, métodos de pago y cuotas. |
| `reviews` | Hechos | Calificaciones y comentarios de los usuarios. |

### 1.3 Hallazgos Clave 💡

* **Granularidad de Clientes:** La distinción entre `customer_id` y `customer_unique_id` permite rastrear el comportamiento recurrente del usuario a través de múltiples órdenes.
* **Consistencia de Datos:** Durante la ingesta se validó la codificación `UTF8` para preservar los caracteres especiales del portugués brasileño en nombres de ciudades y categorías.

## 3) Fase 2: Pre-procesamiento y Calidad de Datos (02_pre_processing_analysis.sql) 🔍

Antes de generar métricas de negocio, se ejecutó un análisis de integridad en este script. Este paso es fundamental para asegurar que las visualizaciones en Power BI no contengan sesgos por datos ruidosos.

### 2.1 Auditoría de Flujo Logístico 🧪

Tras auditar los estados de las órdenes frente a sus fechas de cumplimiento, se obtuvieron los siguientes resultados:

| Estado del Pedido | Total Pedidos | Fechas Nulas | Conclusión de Calidad |
| :--- | :--- | :--- | :--- |
| **delivered** | 96,478 | 8 | **Alta Integridad:** Solo 0.008% de error en registro de entrega. |
| **shipped** | 1,107 | 1,107 | **Consistencia Lógica:** Pedidos en tránsito correctamente sin fecha final. |
| **canceled** | 625 | 619 | **Excepción:** 6 pedidos cancelados reportan entrega (posible retorno). |


### 2.2 Resolución de Conflictos Geográficos 📍

Se validó la cardinalidad de la tabla `geolocation`.
* **Hallazgo:** El campo `geolocation_zip_code_prefix` presenta múltiples registros por código postal (coordenadas redundantes).
* **Impacto en el Modelo:** Esta duplicidad impide el uso del código postal como Primary Key. Se documenta que cualquier JOIN con esta tabla debe realizarse tras un proceso de agregación (promedio de latitud/longitud) para evitar la explosión de filas.

### 2.3 Perfilado Estadístico Financiero 💰

Se aplicaron funciones de agregación para entender la distribución de precios en `order_items`:
* **Métricas Evaluadas:** Mínimos, Máximos, Promedios y Desviación Estándar.
* **Insight:** La alta desviación estándar detectada confirma la heterogeneidad del catálogo de Olist. Esto justifica la necesidad de segmentar los reportes por categorías para que los promedios de venta no se vean distorsionados por artículos de lujo o de muy bajo costo.

| Métrica | Valor Analizado | Implicación de Negocio |
| :--- | :--- | :--- |
| **Nulos en Fechas** | Detectados en `delivered` | Afecta la medición de satisfacción del cliente. |
| **Duplicados Geo** | Alta frecuencia por prefijo | Requiere limpieza antes de mapeo espacial. |
| **Outliers de Precio** | Identificados mediante STDDEV | Necesidad de filtrado de valores atípicos. |

## 4) Guía de Ejecución ⚙️
1. **Preparación:** Crear la base de datos `olist_analytics` y asegurar la conexión.
2. **Infraestructura e Ingesta:** Ejecutar `01_schema_and_load.sql`.

   > **Nota:** Actualizar las rutas del comando `COPY` a la ubicación local de tus archivos CSV.

3. **Validación de Calidad:** Ejecutar `02_pre_processing_analysis.sql` para verificar la integridad de la carga y auditar nulos.
4. **Capa Analítica (Próximamente):** Ejecutar `03_views.sql` para generar las tablas finales de Power BI.

