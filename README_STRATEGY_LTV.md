# LTV & Performance Strategy Benchmark

Este documento fundamenta la arquitectura de alto rendimiento elegida para el **Lakehouse Banking dbt Project** y detalla el impacto directo sobre la rentabilidad del negocio (LTV).

## 1. Ingeniería de Desempeño y Reducción de Costos Operativos

Para manejar con agilidad el volumen de **+50MM de transacciones** de la capa Silver manteniendo los costes de cómputo en Databricks bajos, establecimos tres pilares de eficiencia en `dbt_project.yml`:

*   **Liquid Clustering:** A diferencia del particionamiento estático (`partition_by`), Liquid Clustering optimiza asíncronamente el tamaño de los ficheros y agiliza el Data Skipping (obviando la lectura de terabytes innecesarios al consultar un subconjunto). Lo hemos configurado en las claves de cardinalidad más complejas (`customer_id`, `transaction_date`).
*   **Merge Incremental:** Usando la estrategia `merge` en nuestra tabla masiva de `transactions`, garantizamos que únicamente las filas modificadas (`amount_usd`, `validation_reason`) generan operaciones de I/O en la base de datos (UPSERT determinista), ahorrando tiempo de carga (Time-to-Load).
*   **Vistas Materializadas (Materialized Views):** Las capas finales que se exponen a Business Intelligence (Looker/Power BI) como el `customer_360`, están pre-computadas por las Materialized Views de Databricks SQL. Proveen tiempos de carga inferiores a **2 segundos**, re-calculándose automáticamente solo cuando el *underlying data* cambia.

## 2. Modelado Estratégico "Gold" (dim_customer_360_value)

La capa Gold ha evolucionado de un simple almacén a un motor de predicción que ayuda al negocio a elevar el LTV global:

*   **Operational Latency (`days_to_activation_latency`):** Mide la eficiencia del Onboarding. Si un cliente demora semanas desde que se captura su perfil hasta que realiza la primera transacción activa, expone fricciones en la usabilidad del App Bancaria. Un valor bajo correlaciona fuertemente con una mayor recurrencia a futuro.
*   **Cross-Selling Gap (`cross_sell_loan_propensity`):** Categoriza proactivamente clientes con exceso de liquidez (e.g. `$10,000+` en pasivos) pero que carecen de tarjetas de crédito o hipotecas con nuestro banco. Proveer esta lista a los equipos de Marketing incrementará sensiblemente el ingreso por servicios (Cross-Sell).
*   **Churn Prediction:** Medimos la caída actual de las cuentas (a través de macro-funciones de `rolling_windows`) comparando las transacciones de los últimos 30 días contra el promedio histórico de vida útil del usuario. 

*Implementamos funciones UDF Vectorized de Python para Machine Learning (Pandas UDFs sobre Spark) en otras capas del ciclo para integrar Scoring predictivo avanzado.*

## 3. Conclusión de Framework-First
Estas decisiones arquitectónicas han convertido nuestra red de pipelines en verdaderos cimientos *Lego*. Cada regla (Auditoría, PII Hash, Rolling Averages, Testing) es un componente DRY que soporta cientos de millones de escaneos a la latencia más baja posible del mercado.
