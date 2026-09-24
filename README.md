# Análisis de rentabilidad de clientes

Proyecto de portafolio para comparar ingresos, costos y margen bruto frente al presupuesto, e identificar clientes y divisiones con menor rentabilidad.

**Autor:** Edwar Mia Aguirre  
**Herramientas:** Excel · Power Query · MySQL · Power BI  
**Alcance:** 47.646 registros financieros, de agosto de 2013 a noviembre de 2014.

## Trabajo realizado

- Limpieza de fechas, importes y textos; identificación de clientes ausentes del catálogo.
- Modelo estrella con una tabla de hechos y cinco dimensiones.
- Consultas SQL y medidas DAX, con resultados contrastados entre herramientas.
- Dashboard con resumen ejecutivo, análisis de clientes y divisiones.

## Principales resultados

- Ingresos reales de **117,88 millones**, un **0,47 %** superiores al presupuesto.
- Margen bruto de **41,78 millones**, equivalente al **35,44 %** de los ingresos.
- Margen **10,61 millones por debajo del presupuesto**, asociado al exceso de costos.
- La división Principal concentra aproximadamente el **64,6 %** de la desviación negativa del margen.

## Archivos del proyecto

Excel, CSV preparados, scripts SQL, informe Power BI y documentación del análisis.

Para actualizar el PBIX, se necesita configurar la conexión a MySQL y la base `rentabilidad_clientes` con credenciales propias.

## Fuente

[Customer Profitability Sample — Microsoft y obviEnce](https://learn.microsoft.com/en-us/power-bi/create-reports/sample-customer-profitability).

Proyecto educativo con datos de muestra. Los importes se presentan sin atribuir una moneda y el margen bruto no equivale al beneficio neto.
