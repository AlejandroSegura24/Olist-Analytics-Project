# 🚀 Olist E-commerce Analytics: De Datos Crudos a Insights de Negocio

Análisis integral de datos de ventas del e-commerce brasileño **Olist**, abarcando el período 2016–2018. El proyecto cubre desde la carga y limpieza de datos en PostgreSQL hasta la visualización interactiva en Power BI, con el objetivo de demostrar un flujo de análisis de datos end-to-end.

---

## 🏢 Contexto del negocio

**Olist** es una plataforma brasileña de e-commerce que conecta pequeños comerciantes con los principales marketplaces del país. El dataset utilizado proviene de [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) y contiene información real de la empresa, debidamente anonimizada, sobre órdenes, productos, clientes, vendedores, pagos y reseñas entre 2016 y 2018.

Este análisis busca responder preguntas clave de negocio como:
- ¿Qué meses y categorías generan más ingresos?
- ¿Cómo se comportan las ventas a lo largo del tiempo?
- ¿Cuáles son los métodos de pago preferidos por los clientes?

---

## 🎯 Objetivo del proyecto

Demostrar un flujo completo de análisis de datos que incluye:
- Modelado y carga de datos relacionales en PostgreSQL
- Limpieza y validación de calidad de datos con SQL
- Generación de vistas optimizadas para consumo en herramientas de BI
- Construcción de un dashboard interactivo y profesional en Power BI

---

## 🔄 Arquitectura del proyecto
```
Archivos CSV (Olist)
       ↓
PostgreSQL — Carga y modelado del schema
       ↓
SQL — Limpieza, validación y vistas
       ↓
Power BI — Visualización e insights
```

---

## 📁 Estructura del proyecto
```
OLIST-ANALYTICS-PROJECT/
│
├── assets/                          # Imágenes de soporte para la documentación
│   ├── erd_diagram.png              # Diagrama entidad-relación del modelo de datos
│   ├── financial_audit_results.png  # Resultados del análisis financiero
│   ├── logistics_impact.png         # Análisis de impacto logístico
│   ├── top_categories.png           # Visualización de categorías principales
│   └── view_finance.png             # Vista de la consulta financiera en PostgreSQL
│
├── database/                           # Scripts de carga y preprocesamiento
│   ├── 01_schema_and_load.sql          # Creación del schema y carga de archivos CSV
│   ├── 02_pre_processing_analysis.sql  # Validación de nulos, duplicados y faltantes
│   └── README.md
│z
├── power bi/                                              # Dashboard interactivo de ventas
│   ├── Olist_Sales_Analysis_v1_2026-02-12.Report/         # Carpeta de reporte
│   ├── Olist_Sales_Analysis_v1_2026-02-12.SemanticModel/  # Modelo semántico
│   ├── Olist_Sales_Analysis_v1_2026-02-12.pbip            # Archivo principal Power BI
│   └── README.md
│
├── sql_queries/                     # Consultas y lógica de negocio
│   ├── 01_views.sql                 # Vistas optimizadas para Power BI (excluye nulos)
│   ├── 02_business_logic.sql        # Consultas de análisis exploratorio
│   └── README.md
│
├── .gitignore
└── README.md
```

---

## 🛠️ Herramientas utilizadas

| Herramienta | Uso |
|---|---|
| PostgreSQL | Base de datos relacional, carga y modelado |
| SQL | Limpieza, validación y generación de vistas |
| Power BI | Visualización e interactividad |

---

## 🔍 Hallazgos principales

Los siguientes insights fueron extraídos del dashboard de ventas:

**Comportamiento mensual**
- Noviembre presentó la mayor subida porcentual del período, con un **+44.6%** respecto al mes anterior.

**Comportamiento por categoría**
- **Watches Gifts** es una categoría destacada: siendo la **N°7** en volumen de ventas, se posiciona como la **N°2** categoría con mayor valor de ingresos, situándose por encima del promedio general de **R$ 1.27** millones.

**Métodos de pago**
- Aproximadamente el **75,3%** de las compras se realizan con tarjeta de crédito, siendo el método de pago ampliamente dominante frente a boleto, voucher y débito.

---

## ▶️ Cómo reproducir el proyecto

1. Clona el repositorio
2. Crea una base de datos en PostgreSQL
3. Ejecuta `/database/01_schema_and_load.sql` para crear el schema y cargar los datos
4. Ejecuta `/database/02_pre_processing_analysis.sql` para validar la calidad de los datos
5. Ejecuta `/sql_queries/01_views.sql` para generar las vistas
6. Ejecuta `/sql_queries/02_business_logic.sql` para los análisis adicionales
7. Abre el archivo `.pbip` en Power BI Desktop y conecta a tu instancia de PostgreSQL

---

## 👤 Autor

**David Alejandro Segura**
[LinkedIn](http://www.linkedin.com/in/david-alejandro-segura) · [GitHub](https://github.com/AlejandroSegura24)