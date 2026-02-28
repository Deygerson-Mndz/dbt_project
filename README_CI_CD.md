# Analytics Development Lifecycle (ADLC) - CI/CD Guía

Bienvenido al esquema de integración y despliegue continuo de nuestro proyecto de dbt sobre Databricks Lakehouse.

## Diagrama de Flujo (Promotion)

1. **Desarrollo (Local/Dev):** 
   - Ramas: `feature/*`, `bugfix/*`
   - Los ingenieros operan contra el catálogo de desarrollo (`dev_catalog`) usando variables locales.
2. **Pruebas y QA (Slim CI):**
   - Ramas: `qa`
   - Cuando se levanta un PR hacia `qa`, GitHub Actions corre un entorno Slim. Solo se probarán con `dbt build` los modelos que se han modificado y sus hijos (haciendo diferimiento al manifiesto anterior: `state:modified+`). Evita procesar toda la base de 50MM de transacciones si no fue tocada.
3. **Producción (Prod Gate & Docs):**
   - Ramas: `prod`/`main`
   - Cuando se hace push o merge hacia `prod`, el CI/CD corre un despliegue completo (`dbt build --target prod`), genera los Data Contracts de calidad (`dbt test`) y finalmente construye y despliega nuestro Catálogo de Datos interactivo (`dbt docs generate`).

---

## Estructura de Proyecto bajo dbt Core Best Practices

El proyecto debe mantener esta estructura obligatoriamente:
- `/models`: Todos los modelos (separados en schemas `staging`, `silver` y `gold`).
- `/tests`: Singular tests específicos que no caben en los YAMLs como `dbt-expectations`.
- `/macros`: Fragmentos reutilizables Jinja (macros de vistas, auditoría y enmascaramiento).
- `/snapshots`: Snapshots para Type 2 SCD (Tablas Tipo 2 en las dimensiones si es requerido).
- `/seeds`: Componentes estáticos (como mapeos estáticos o datasets de prueba).

---

## Interpretación de Fallos en GitHub Actions

Si un Action falla, revisa los siguientes puntos críticos:

**1. Falla SQLFluff (Linting):**
El pipeline arrojará un error de `sqlfluff`. Esto significa que una consulta SQL no sigue nuestro código de estilo (ej. Palabras reservadas no están en mayúsculas). 
*Solución:* Corre localmente `sqlfluff fix models/` antes de pushear tu código.

**2. Falla en Slim CI (Slim Build/Test):**
La ejecución de `dbt build --select state:modified+` puede fallar si uno de los Data Contracts (como que `amount_usd` debe ser > 0) que agregaste para un nuevo modelo falló. 
*Solución:* Revisa los registros expuestos por dbt en la consola de GHA (busca 'FAIL' rojo) y asegúrate que tus transformaciones o semillas cumplan las reglas de los `.yml`.

**3. Fallo en Conexión a Databricks (Target Exception):**
*Solución:* El DevOps Team deberá revisar si en Settings -> Secrets and variables -> Actions, las variables `DATABRICKS_HOST`, `DATABRICKS_TOKEN`, y `DATABRICKS_HTTP_PATH` están vencidas.
