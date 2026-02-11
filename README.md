# 🚀 Olist E-commerce Analytics: De Datos Crudos a Insights de Negocio

## 📝 Descripción
Este proyecto consiste en el diseño e implementación de una solución de **Analytics Engineering** para el dataset real de **Olist**, el marketplace más grande de Brasil. El objetivo principal es transformar una estructura de datos fragmentada en archivos CSV en una base de datos relacional optimizada en **PostgreSQL**, culminando en un dashboard estratégico para la toma de decisiones.

A través de este pipeline, se resuelven desafíos de normalización, integridad referencial y limpieza de datos, permitiendo analizar el ciclo de vida completo de una orden: desde la captación del cliente hasta la post-venta.

---

## 🛠️ Tecnologías Usadas
* **Base de Datos:** PostgreSQL 16.
* **Lenguajes:** SQL (PostgreSQL Dialect).
* **Visualización:** Power BI (DAX & Data Modeling).
* **Metodologías:** Analytics Engineering, Documentación Técnica y Diseño de ERD.

---

## 🔄 Flujo del Proyecto
Para garantizar la calidad de los insights, el proyecto sigue una metodología estructurada en 4 etapas:

1.  **Ingesta e Infraestructura (DDL) 🏗️:** Definición de esquemas, tipos de datos precisos (`DECIMAL`, `TIMESTAMP`) y carga masiva mediante comandos `COPY`.
2.  **Auditoría y Calidad (Profiling) 🔍:** Identificación de nulos, eliminación de duplicados geográficos y validación de integridad financiera (análisis de intereses por cuotas).
3.  **Modelado Semántico (Vistas) 📈:** Creación de capas de abstracción lógicas en SQL para simplificar el consumo de datos desde herramientas de BI.
4.  **Visualización Estratégica 🖥️:** Construcción de KPIs clave (SLA de entrega, Revenue, Satisfacción) en Power BI.

---

## 📂 Estructura del Repositorio

Para mantener el código limpio, modular y fácil de mantener, el proyecto se organiza de la siguiente manera:

```text
PROYECTO_OLIST/
├── database/                         # Infraestructura de datos en PostgreSQL
│   ├── 01_schema_and_load.sql          # DDL y scripts de ingesta (COPY)
│   ├── 02_pre_processing_analysis.sql  # Auditoría de calidad y nulos
|   └── README.md                       # Documentación de cada etapa
├── sql_queries/                      # Laboratorio de experimentación SQL
│   ├── 01_views.sql                    # Análisis inicial y hallazgos
│   ├── 02_business_logic.sql           # Prototipos de joins complejos
|   └── README.md                       # Documentación de cada etapa
├── power_bi/                         # Archivos fuente de Power BI
│   ├── olist_report.pbip               # Proyecto maestro
│   └── .SemanticModel/                 # Medidas DAX y relaciones
└── assets/                           # Recursos visuales y documentación (Capturas)
```

---

## 📊 Resultados e Insights Destacados

### 1. El Costo de la Espera 🚚
A través de nuestro análisis de correlación, identificamos que las órdenes calificadas como **"Críticas" (+30 días)** tienen una satisfacción promedio de **~1.2 estrellas**, mientras que las entregas en menos de una semana mantienen un promedio de **4.2+**. Esto valida que la logística es el principal motor del NPS en Olist.

### 2. Financiamiento como Motor de Venta 💳
El análisis financiero reveló que el excedente pagado por los clientes no es un error de datos, sino un **modelo de cuotas con intereses**. Las ventas en 10+ cuotas representan un flujo de caja constante, pero con un costo financiero para el cliente que debe ser monitoreado para evitar tasas de cancelación.

### 3. Concentración de Mercado 📍
El **Market Share** está fuertemente concentrado en estados específicos (ej. SP), lo que sugiere oportunidades de optimización en centros de distribución regionales para reducir el "Nudo Crítico Logístico".