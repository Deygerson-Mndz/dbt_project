# QA Automation & Destructive Test Plan (Data Reliability)

Este documento define la estrategia de pruebas extremas ("Stress & Break") para garantizar la resiliencia del pipeline Lakehouse Medallion.

## 1. Escenarios de "Stress & Break"
Hemos creado semillas destructivas (`seeds/destructive_tests/`) que inyectan intencionalmente:
- **Fechas Nulas y Futuras:** Para verificar que las constraints temporales o partiociones no colapsen y caigan al `_rej`.
- **Inyección SQL y Caracteres Especiales en PII:** Para estresar el macro de enmascaramiento `mask_pii(card_number)`. Validamos si el hash `SHA-256` falla al recibir Unicode/Emojis u arroja outputs vacíos.
- **Valores Financieros Ilógicos:** Montos o ingresos iguales a cero o negativos.

## 2. Integridad Referencial ("Orphan Records")
Se implementó un test singular en dbt (`tests/assert_no_orphan_transactions.sql`).
- **Objetivo:** Garantizar que ninguna transacción en la capa Silver (`int_transactions`) carezca de un `customer_id` existente en `stg_customers`.
- *Riesgo mitigado:* Tablas Gold asimétricas y reportes inconsistentes de PowerBI por INNER JOINs fallidos.

## 3. Demostración de Schema Evolution
En Databricks, las tablas Silver/Gold usan Delta Lake. Para probar el **Schema Evolution**:
1. Agregamos una columna ficticia en la tabla Bronze.
2. Comprobamos la caída de ejecución.
3. Arreglo en pipeline: Modificar la estrategia incremental de configuración dbt a `on_schema_change: 'append_new_columns'` o `sync_all_columns`. 
   *(Actualmente los modelos incrementales obligarán un Full Refresh seguro si este caso ocurre sin permiso).*

## 4. Regresión y Data Drift
Se incorporaron métricas de distribución en YAML usando `dbt-expectations`:
- Revisamos la media y desviación estándar de la columna `credit_score` de los clientes en la tabla analítica.
- Si el macro entorno cambia abruptamente (Data Drift), el pipeline fallará de forma preventiva, protegiendo los Modelos de ML aguas abajo.

---
## 5. Estabilidad Operativa y Performance

### Volume Testing (50MM+ TtoL)
* **Plan de Ejecución:** Inyectar artificialmente la misma semilla 50 millones de veces mediante un PySpark job directo al catálogo Bronze, seguido de un `dbt run`.
* **Criterio de Aceptación:** El insert incremental con particiones por fecha (`transaction_date`) no debe sobrepasar los 10 minutos permitidos en la ventana del SLA batch.

### Prueba de Idempotencia
Se incluye el test `tests/assert_idempotency_fct_transactions.sql`.
* **Escenario:** `dbt run --select fct_transactions` se lanza tres veces consecutivas para el mismo Timestamp particionado sin datos nuevos.
* **Aserción:** Evaluamos mediante un conteo agrupado que `COUNT(transaction_id)` base siga siendo exactamente igual a `1` a pesar de las tres corridas.
