# Dashboard Blueprint: Strategic ROI & C-Suite Metrics

Como Principal AI & Analytics Engineer, este es el diseño estructural del panel directivo (Looker/PowerBI) que se alimentará de nuestra nueva capa Gold (`dim_customer_360_value` y `fct_transactions`). 

El objetivo de este dashboard es que el CFO y el Directorio puedan justificar la inversión del proyecto Lakehouse a través del impacto directo en el P&L (Profit and Loss) y la reducción del riesgo operativo o abandono del cliente (Churn).

## Los 5 KPIs Estratégicos (C-Suite View)

### 1. Índice de Latencia Operativa de Onboarding ("Time-to-Revenue")
*   **Métrica:** Promedio de días entre la apertura de cuenta y la primera transacción fondeada (`days_to_activation_latency`).
*   **Impacto Financiero:** Identifica fricciones en el proceso KYC o en la app móvil. Bajar este número de 7 días a 2 días acelera el retorno sobre el costo de adquisición (CAC) en millones al año.
*   **Visualización:** Gráfico de tendencias mensuales + Alerta (Rojo > 5 días).

### 2. Tasa de Fugas (Early Churn Propensity)
*   **Métrica:** % de clientes cuyo volumen transaccional de los últimos 30 días ha caído un >50% respecto a su media histórica (`tx_count_30d` vs `expected_monthly_tx`).
*   **Impacto Financiero:** Prevención de pérdida de depósitos. Permite activar campañas automatizadas de retención *antes* de que el usuario vacíe la cuenta.
*   **Visualización:** Funnel de retención y tabla de clientes top-tier "En Riesgo".

### 3. Oportunidad Pura de Cross-Selling (The Un-tapped Goldmine)
*   **Métrica:** Suma total de liquidez estancada en clientes sin productos de crédito (`total_liquid_assets` donde `cross_sell_loan_propensity = HIGH_PROBABILITY`).
*   **Impacto Financiero:** Cuantifica exactamente cuánto dinero (ej. $500MM estancados) el banco podría aspirar a apalancar ofreciendo tarjetas pre-aprobadas a usuarios sin riesgo crediticio (ya que son sus propios fondos).
*   **Visualización:** Gauge (Termómetro) de Liquidez Pasiva vs Tasa de Conversión a Crédito.

### 4. Tasa de Conformidad PCI-DSS & Data Quality (Risk Mitigation)
*   **Métrica:** Volumen de transacciones enviadas a tablas de rechazo `_rej` / Total de Ingesta (+50MM) en capa Silver.
*   **Impacto Financiero:** Mide el nivel de "Toxicidad" del dato que proviene del Core Legacy. Cada registro en `_rej` que no ensucia Gold salva multas regulatorias y errores catastróficos en Modelos ML. Adicionalmente, reporta el % de registros donde el enmascaramiento criptográfico (`mask_pii`) bloqueó fugas de datos.
*   **Visualización:** Treemap del `rejection_reason` (Ej. Montos Negativos, Tarjetas Inválidas).

### 5. Eficiencia de FinOps y Databricks ROI (Cost per Query)
*   **Métrica:** Disminución métrica del costo (DBU) procesando los mismos 50MM de registros bajo Liquid Clustering vs Legacy.
*   **Impacto Financiero:** El CFO valida directamente el ROI de la ingeniería. Mostrar cómo calcular el `Rolling Window` usando SQL nativo incremental reduce el procesamiento de un clúster de 10 nodos por 4 horas a tan solo 5 minutos por lote.
*   **Visualización:** Bar chart combinando Volumen Procesado (subiendo) vs DBU Cost (bajando o plano).

---
## Conexión a Machine Learning (AI Readiness)
Este panel no es el techo, es el suelo. Al estandarizar e hiper-sintetizar variables limpiezas como el Churn Score y la Latencia, la capa `Gold` sirve desde hoy como el **Feature Store** oficial para conectar nuestros clústeres de MLflow en Databricks, alimentando en tiempo real modelos predictivos de Default de Préstamo que el departamento de Riesgos desplegará en el Q próximo.
