CREATE DATABASE IF NOT EXISTS rentabilidad_clientes
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

    USE rentabilidad_clientes;
SELECT
    DATABASE() AS base_actual,
    VERSION() AS version_mysql;
    
    CREATE TABLE dim_productos (
    ID_Producto INT NOT NULL,
    Producto VARCHAR(150) NOT NULL,
    PRIMARY KEY (ID_Producto)
);

SELECT *
FROM dim_productos
ORDER BY ID_Producto;

CREATE TABLE dim_escenarios (
    ID_Escenario INT NOT NULL,
    Escenario VARCHAR(30) NOT NULL,
    PRIMARY KEY (ID_Escenario)
);

CREATE TABLE dim_unidades_negocio (
    ID_Unidad_Negocio INT NOT NULL,
    Unidad_Negocio VARCHAR(100),
    Division VARCHAR(50),
    ID_Ejecutivo INT,
    Division_ES VARCHAR(50),
    Nombre_Ejecutivo VARCHAR(150),
    PRIMARY KEY (ID_Unidad_Negocio)
);

CREATE TABLE dim_calendario (
    Anio_Periodo INT NOT NULL,
    Anio INT NOT NULL,
    Periodo INT NOT NULL,
    Fecha DATE NOT NULL,
    Mes VARCHAR(20),
    ID_Trimestre INT,
    Trimestre VARCHAR(10),
    Mes_ES VARCHAR(20),
    Trimestre_ES VARCHAR(10),
    Mes_Anio VARCHAR(30),
    PRIMARY KEY (Anio_Periodo)
);

SELECT
    COUNT(*) AS total_periodos,
    MIN(Fecha) AS primera_fecha,
    MAX(Fecha) AS ultima_fecha
FROM rentabilidad_clientes.dim_calendario;

SELECT *
FROM rentabilidad_clientes.dim_calendario
ORDER BY Anio_Periodo
LIMIT 5;

UPDATE dim_calendario
SET Fecha = STR_TO_DATE(
    CONCAT(Anio_Periodo, '01'),
    '%Y%m%d'
)
WHERE Anio_Periodo BETWEEN 200801 AND 201412;

SELECT
    COUNT(*) AS total_periodos,
    MIN(Fecha) AS primera_fecha,
    MAX(Fecha) AS ultima_fecha,
    SUM(
        CASE
            WHEN Fecha <=> STR_TO_DATE(
                CONCAT(Anio_Periodo, '01'),
                '%Y%m%d'
            ) THEN 0
            ELSE 1
        END
    ) AS fechas_incorrectas
FROM dim_calendario;

CREATE TABLE stg_clientes (
    ID_Cliente VARCHAR(30),
    Nombre_Cliente VARCHAR(255),
    Ciudad VARCHAR(150),
    Codigo_Postal VARCHAR(30),
    Estado_Provincia VARCHAR(100),
    ID_Sector VARCHAR(30),
    Pais_Codigo VARCHAR(20),
    Pais VARCHAR(100),
    Sector_ES VARCHAR(150),
    Estado_Sector VARCHAR(150),
    Sector_Analisis VARCHAR(150),
    Estado_Catalogo_Cliente VARCHAR(150)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

SELECT
    COUNT(*) AS total_filas,
    COUNT(DISTINCT TRIM(ID_Cliente)) AS clientes_distintos
FROM stg_clientes;

SELECT
    TRIM(Estado_Catalogo_Cliente) AS estado_catalogo,
    COUNT(*) AS cantidad
FROM stg_clientes
GROUP BY TRIM(Estado_Catalogo_Cliente)
ORDER BY estado_catalogo;

CREATE TABLE dim_clientes (
    ID_Cliente INT NOT NULL,
    Nombre_Cliente VARCHAR(255) NOT NULL,
    Ciudad VARCHAR(150),
    Codigo_Postal VARCHAR(30),
    Estado_Provincia VARCHAR(100),
    ID_Sector INT,
    Pais_Codigo VARCHAR(20),
    Pais VARCHAR(100),
    Sector_ES VARCHAR(150),
    Estado_Sector VARCHAR(150),
    Sector_Analisis VARCHAR(150),
    Estado_Catalogo_Cliente VARCHAR(150),
    PRIMARY KEY (ID_Cliente)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT INTO dim_clientes (
    ID_Cliente,
    Nombre_Cliente,
    Ciudad,
    Codigo_Postal,
    Estado_Provincia,
    ID_Sector,
    Pais_Codigo,
    Pais,
    Sector_ES,
    Estado_Sector,
    Sector_Analisis,
    Estado_Catalogo_Cliente
)
SELECT
    CAST(NULLIF(TRIM(ID_Cliente), '') AS SIGNED),
    NULLIF(TRIM(Nombre_Cliente), ''),
    NULLIF(TRIM(Ciudad), ''),
    NULLIF(TRIM(Codigo_Postal), ''),
    NULLIF(TRIM(Estado_Provincia), ''),
    CAST(NULLIF(TRIM(ID_Sector), '') AS SIGNED),
    NULLIF(TRIM(Pais_Codigo), ''),
    NULLIF(TRIM(Pais), ''),
    NULLIF(TRIM(Sector_ES), ''),
    NULLIF(TRIM(Estado_Sector), ''),
    NULLIF(TRIM(Sector_Analisis), ''),
    NULLIF(TRIM(Estado_Catalogo_Cliente), '')
FROM stg_clientes;

SELECT COUNT(*) AS total_clientes
FROM dim_clientes;

SELECT
    Estado_Catalogo_Cliente,
    COUNT(*) AS cantidad
FROM dim_clientes
GROUP BY Estado_Catalogo_Cliente
ORDER BY Estado_Catalogo_Cliente;

SELECT
    ID_Cliente,
    Nombre_Cliente,
    ID_Sector,
    Estado_Catalogo_Cliente
FROM dim_clientes
WHERE Estado_Catalogo_Cliente = 'Ausente del catálogo de trabajo'
ORDER BY ID_Cliente
LIMIT 5;

SELECT
    Estado_Catalogo_Cliente,
    HEX(Estado_Catalogo_Cliente) AS texto_hexadecimal,
    COUNT(*) AS cantidad
FROM dim_clientes
GROUP BY Estado_Catalogo_Cliente
ORDER BY Estado_Catalogo_Cliente;

SELECT
    ID_Cliente,
    Nombre_Cliente,
    ID_Sector,
    Estado_Catalogo_Cliente
FROM dim_clientes
WHERE Estado_Catalogo_Cliente LIKE 'Ausente%'
ORDER BY ID_Cliente
LIMIT 5;

UPDATE dim_clientes
SET Estado_Catalogo_Cliente = REPLACE(
    Estado_Catalogo_Cliente,
    CONVERT(UNHEX('C383C2A1') USING utf8mb4),
    CONVERT(UNHEX('C3A1') USING utf8mb4)
)
WHERE ID_Cliente >= 0
  AND LOCATE(
      UNHEX('C383C2A1'),
      CAST(Estado_Catalogo_Cliente AS BINARY)
  ) > 0;

SELECT
    Estado_Catalogo_Cliente,
    COUNT(*) AS cantidad
FROM dim_clientes
GROUP BY Estado_Catalogo_Cliente
ORDER BY Estado_Catalogo_Cliente;

SELECT COUNT(*) AS clientes_ausentes
FROM dim_clientes
WHERE Estado_Catalogo_Cliente = 'Ausente del catálogo de trabajo';

SELECT DISTINCT
    Pais,
    Sector_ES,
    Estado_Sector,
    Sector_Analisis
FROM dim_clientes
ORDER BY Pais, Sector_ES;

CREATE TABLE dim_clientes_respaldo LIKE dim_clientes;

INSERT INTO dim_clientes_respaldo
SELECT * FROM dim_clientes;

UPDATE dim_clientes
SET
    Pais = CASE
        WHEN LOCATE(UNHEX('C383'), CAST(Pais AS BINARY)) > 0
        THEN CONVERT(CAST(CONVERT(Pais USING latin1) AS BINARY) USING utf8mb4)
        ELSE Pais
    END,

    Sector_ES = CASE
        WHEN LOCATE(UNHEX('C383'), CAST(Sector_ES AS BINARY)) > 0
        THEN CONVERT(CAST(CONVERT(Sector_ES USING latin1) AS BINARY) USING utf8mb4)
        ELSE Sector_ES
    END,

    Estado_Sector = CASE
        WHEN LOCATE(UNHEX('C383'), CAST(Estado_Sector AS BINARY)) > 0
        THEN CONVERT(CAST(CONVERT(Estado_Sector USING latin1) AS BINARY) USING utf8mb4)
        ELSE Estado_Sector
    END,

    Sector_Analisis = CASE
        WHEN LOCATE(UNHEX('C383'), CAST(Sector_Analisis AS BINARY)) > 0
        THEN CONVERT(CAST(CONVERT(Sector_Analisis USING latin1) AS BINARY) USING utf8mb4)
        ELSE Sector_Analisis
    END
WHERE ID_Cliente >= 0;

SELECT DISTINCT
    Pais,
    Sector_ES,
    Estado_Sector,
    Sector_Analisis
FROM dim_clientes
ORDER BY Pais, Sector_ES;

SELECT
    ID_Cliente,
    Nombre_Cliente,
    Ciudad,
    Estado_Provincia
FROM dim_clientes
WHERE LOCATE(
    UNHEX('C383'),
    CAST(CONCAT_WS(' ', Nombre_Cliente, Ciudad, Estado_Provincia) AS BINARY)
) > 0;

USE rentabilidad_clientes;

UPDATE dim_clientes
SET Nombre_Cliente = CONVERT(
    CAST(CONVERT(Nombre_Cliente USING latin1) AS BINARY)
    USING utf8mb4
)
WHERE ID_Cliente = 10181
  AND LOCATE(
      UNHEX('C383'),
      CAST(Nombre_Cliente AS BINARY)
  ) > 0;

SELECT
    ID_Cliente,
    Nombre_Cliente,
    Ciudad,
    Estado_Provincia
FROM dim_clientes
WHERE ID_Cliente = 10181;

USE rentabilidad_clientes;
CREATE TABLE stg_finanzas (
    Anio_Periodo VARCHAR(30),
    ID_Cliente VARCHAR(30),
    ID_Producto VARCHAR(30),
    ID_Unidad_Negocio VARCHAR(30),
    ID_Escenario VARCHAR(30),
    Ingresos VARCHAR(100),
    Costos_Materiales VARCHAR(100),
    Costos_Mano_Obra_Variable VARCHAR(100),
    Impuestos VARCHAR(100),
    Ingresos_por_Gastos_Viaje VARCHAR(100),
    Gastos_Viaje VARCHAR(100),
    Costos_Terceros VARCHAR(100),
    Ingresos_Suscripciones VARCHAR(100),
    Fecha_Periodo VARCHAR(30)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

SELECT COUNT(*) AS total_registros
FROM stg_finanzas;

SELECT
    TRIM(ID_Escenario) AS escenario,
    COUNT(*) AS cantidad
FROM stg_finanzas
GROUP BY TRIM(ID_Escenario)
ORDER BY escenario;

SELECT
    Ingresos,
    Costos_Materiales,
    Costos_Mano_Obra_Variable,
    Impuestos,
    Ingresos_por_Gastos_Viaje,
    Gastos_Viaje,
    Costos_Terceros,
    Ingresos_Suscripciones,
    Fecha_Periodo
FROM stg_finanzas
WHERE CONCAT_WS(
    '|',
    Ingresos,
    Costos_Materiales,
    Costos_Mano_Obra_Variable,
    Impuestos,
    Ingresos_por_Gastos_Viaje,
    Gastos_Viaje,
    Costos_Terceros,
    Ingresos_Suscripciones
) REGEXP '[.,eE]'
LIMIT 5;

USE rentabilidad_clientes;

CREATE TABLE fact_finanzas (
    ID_Registro BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    Anio_Periodo INT NOT NULL,
    ID_Cliente INT NOT NULL,
    ID_Producto INT NOT NULL,
    ID_Unidad_Negocio INT NOT NULL,
    ID_Escenario INT NOT NULL,
    Ingresos DECIMAL(30,12),
    Costos_Materiales DECIMAL(30,12),
    Costos_Mano_Obra_Variable DECIMAL(30,12),
    Impuestos DECIMAL(30,12),
    Ingresos_por_Gastos_Viaje DECIMAL(30,12),
    Gastos_Viaje DECIMAL(30,12),
    Costos_Terceros DECIMAL(30,12),
    Ingresos_Suscripciones DECIMAL(30,12),
    Fecha_Periodo DATE NOT NULL,
    PRIMARY KEY (ID_Registro)
) ENGINE = InnoDB;

INSERT INTO fact_finanzas (
    Anio_Periodo,
    ID_Cliente,
    ID_Producto,
    ID_Unidad_Negocio,
    ID_Escenario,
    Ingresos,
    Costos_Materiales,
    Costos_Mano_Obra_Variable,
    Impuestos,
    Ingresos_por_Gastos_Viaje,
    Gastos_Viaje,
    Costos_Terceros,
    Ingresos_Suscripciones,
    Fecha_Periodo
)
SELECT
    CAST(NULLIF(TRIM(Anio_Periodo), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(ID_Cliente), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(ID_Producto), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(ID_Unidad_Negocio), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(ID_Escenario), '') AS UNSIGNED),

    CASE WHEN LOWER(Ingresos) LIKE '%e%'
        THEN CAST(CAST(REPLACE(TRIM(Ingresos), ',', '.') AS DOUBLE) AS DECIMAL(30,12))
        ELSE CAST(NULLIF(REPLACE(TRIM(Ingresos), ',', '.'), '') AS DECIMAL(30,12))
    END,

    CASE WHEN LOWER(Costos_Materiales) LIKE '%e%'
        THEN CAST(CAST(REPLACE(TRIM(Costos_Materiales), ',', '.') AS DOUBLE) AS DECIMAL(30,12))
        ELSE CAST(NULLIF(REPLACE(TRIM(Costos_Materiales), ',', '.'), '') AS DECIMAL(30,12))
    END,

    CASE WHEN LOWER(Costos_Mano_Obra_Variable) LIKE '%e%'
        THEN CAST(CAST(REPLACE(TRIM(Costos_Mano_Obra_Variable), ',', '.') AS DOUBLE) AS DECIMAL(30,12))
        ELSE CAST(NULLIF(REPLACE(TRIM(Costos_Mano_Obra_Variable), ',', '.'), '') AS DECIMAL(30,12))
    END,

    CASE WHEN LOWER(Impuestos) LIKE '%e%'
        THEN CAST(CAST(REPLACE(TRIM(Impuestos), ',', '.') AS DOUBLE) AS DECIMAL(30,12))
        ELSE CAST(NULLIF(REPLACE(TRIM(Impuestos), ',', '.'), '') AS DECIMAL(30,12))
    END,

    CASE WHEN LOWER(Ingresos_por_Gastos_Viaje) LIKE '%e%'
        THEN CAST(CAST(REPLACE(TRIM(Ingresos_por_Gastos_Viaje), ',', '.') AS DOUBLE) AS DECIMAL(30,12))
        ELSE CAST(NULLIF(REPLACE(TRIM(Ingresos_por_Gastos_Viaje), ',', '.'), '') AS DECIMAL(30,12))
    END,

    CASE WHEN LOWER(Gastos_Viaje) LIKE '%e%'
        THEN CAST(CAST(REPLACE(TRIM(Gastos_Viaje), ',', '.') AS DOUBLE) AS DECIMAL(30,12))
        ELSE CAST(NULLIF(REPLACE(TRIM(Gastos_Viaje), ',', '.'), '') AS DECIMAL(30,12))
    END,

    CASE WHEN LOWER(Costos_Terceros) LIKE '%e%'
        THEN CAST(CAST(REPLACE(TRIM(Costos_Terceros), ',', '.') AS DOUBLE) AS DECIMAL(30,12))
        ELSE CAST(NULLIF(REPLACE(TRIM(Costos_Terceros), ',', '.'), '') AS DECIMAL(30,12))
    END,

    CASE WHEN LOWER(Ingresos_Suscripciones) LIKE '%e%'
        THEN CAST(CAST(REPLACE(TRIM(Ingresos_Suscripciones), ',', '.') AS DOUBLE) AS DECIMAL(30,12))
        ELSE CAST(NULLIF(REPLACE(TRIM(Ingresos_Suscripciones), ',', '.'), '') AS DECIMAL(30,12))
    END,

    STR_TO_DATE(TRIM(Fecha_Periodo), '%Y-%m-%d')
FROM stg_finanzas;

SHOW WARNINGS;

SELECT
    COUNT(*) AS total_registros,
    MIN(Fecha_Periodo) AS primera_fecha,
    MAX(Fecha_Periodo) AS ultima_fecha,
    SUM(
        CASE
            WHEN DATE_FORMAT(Fecha_Periodo, '%Y%m') = Anio_Periodo
                 AND DAY(Fecha_Periodo) = 1 THEN 0
            ELSE 1
        END
    ) AS fechas_incorrectas
FROM fact_finanzas;

SELECT
    ID_Escenario,
    COUNT(*) AS registros,
    ROUND(SUM(COALESCE(Ingresos, 0)), 2) AS ingresos,
    ROUND(SUM(
        COALESCE(Costos_Materiales, 0)
        + COALESCE(Costos_Mano_Obra_Variable, 0)
        + COALESCE(Impuestos, 0)
        + COALESCE(Ingresos_por_Gastos_Viaje, 0)
        + COALESCE(Gastos_Viaje, 0)
        + COALESCE(Costos_Terceros, 0)
    ), 2) AS costos,
    ROUND(SUM(
        COALESCE(Ingresos, 0)
        - COALESCE(Costos_Materiales, 0)
        - COALESCE(Costos_Mano_Obra_Variable, 0)
        - COALESCE(Impuestos, 0)
        - COALESCE(Ingresos_por_Gastos_Viaje, 0)
        - COALESCE(Gastos_Viaje, 0)
        - COALESCE(Costos_Terceros, 0)
    ), 2) AS margen_bruto
FROM fact_finanzas
GROUP BY ID_Escenario
ORDER BY ID_Escenario;

SELECT 'Clientes' AS dimension, COUNT(*) AS registros_sin_correspondencia
FROM fact_finanzas f
LEFT JOIN dim_clientes d ON f.ID_Cliente = d.ID_Cliente
WHERE d.ID_Cliente IS NULL

UNION ALL

SELECT 'Productos', COUNT(*)
FROM fact_finanzas f
LEFT JOIN dim_productos d ON f.ID_Producto = d.ID_Producto
WHERE d.ID_Producto IS NULL

UNION ALL

SELECT 'Unidades de negocio', COUNT(*)
FROM fact_finanzas f
LEFT JOIN dim_unidades_negocio d
    ON f.ID_Unidad_Negocio = d.ID_Unidad_Negocio
WHERE d.ID_Unidad_Negocio IS NULL

UNION ALL

SELECT 'Calendario', COUNT(*)
FROM fact_finanzas f
LEFT JOIN dim_calendario d ON f.Anio_Periodo = d.Anio_Periodo
WHERE d.Anio_Periodo IS NULL

UNION ALL

SELECT 'Escenarios', COUNT(*)
FROM fact_finanzas f
LEFT JOIN dim_escenarios d ON f.ID_Escenario = d.ID_Escenario
WHERE d.ID_Escenario IS NULL;

ALTER TABLE fact_finanzas
    ADD CONSTRAINT fk_finanzas_cliente
        FOREIGN KEY (ID_Cliente)
        REFERENCES dim_clientes (ID_Cliente),

    ADD CONSTRAINT fk_finanzas_producto
        FOREIGN KEY (ID_Producto)
        REFERENCES dim_productos (ID_Producto),

    ADD CONSTRAINT fk_finanzas_unidad
        FOREIGN KEY (ID_Unidad_Negocio)
        REFERENCES dim_unidades_negocio (ID_Unidad_Negocio),

    ADD CONSTRAINT fk_finanzas_calendario
        FOREIGN KEY (Anio_Periodo)
        REFERENCES dim_calendario (Anio_Periodo),

    ADD CONSTRAINT fk_finanzas_escenario
        FOREIGN KEY (ID_Escenario)
        REFERENCES dim_escenarios (ID_Escenario);

SELECT
    CONSTRAINT_NAME AS relacion,
    COLUMN_NAME AS columna_finanzas,
    REFERENCED_TABLE_NAME AS tabla_dimension,
    REFERENCED_COLUMN_NAME AS columna_dimension
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'rentabilidad_clientes'
  AND TABLE_NAME = 'fact_finanzas'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY CONSTRAINT_NAME;

CREATE OR REPLACE VIEW vw_finanzas_base AS
SELECT
    f.ID_Registro,
    f.Anio_Periodo,
    f.Fecha_Periodo,
    f.ID_Cliente,
    f.ID_Producto,
    f.ID_Unidad_Negocio,
    f.ID_Escenario,

    COALESCE(f.Ingresos, 0) AS Ingresos,

    COALESCE(f.Costos_Materiales, 0)
        + COALESCE(f.Costos_Mano_Obra_Variable, 0)
        + COALESCE(f.Impuestos, 0)
        + COALESCE(f.Ingresos_por_Gastos_Viaje, 0)
        + COALESCE(f.Gastos_Viaje, 0)
        + COALESCE(f.Costos_Terceros, 0)
        AS Costos_Totales,

    COALESCE(f.Ingresos, 0)
        - COALESCE(f.Costos_Materiales, 0)
        - COALESCE(f.Costos_Mano_Obra_Variable, 0)
        - COALESCE(f.Impuestos, 0)
        - COALESCE(f.Ingresos_por_Gastos_Viaje, 0)
        - COALESCE(f.Gastos_Viaje, 0)
        - COALESCE(f.Costos_Terceros, 0)
        AS Margen_Bruto

FROM fact_finanzas f;

SELECT
    e.Escenario,
    COUNT(*) AS Registros,
    ROUND(SUM(v.Ingresos), 2) AS Ingresos_Totales,
    ROUND(SUM(v.Costos_Totales), 2) AS Costos_Totales,
    ROUND(SUM(v.Margen_Bruto), 2) AS Margen_Bruto,
    ROUND(
        100 * SUM(v.Margen_Bruto)
        / NULLIF(SUM(v.Ingresos), 0),
        2
    ) AS Margen_Porcentaje
FROM vw_finanzas_base v
JOIN dim_escenarios e
    ON v.ID_Escenario = e.ID_Escenario
GROUP BY e.ID_Escenario, e.Escenario
ORDER BY e.ID_Escenario;

USE rentabilidad_clientes;

WITH resumen_divisiones AS (
    SELECT
        u.Division_ES,

        SUM(CASE WHEN v.ID_Escenario = 1
            THEN v.Ingresos ELSE 0 END) AS ingresos_reales,

        SUM(CASE WHEN v.ID_Escenario = 2
            THEN v.Ingresos ELSE 0 END) AS ingresos_presupuesto,

        SUM(CASE WHEN v.ID_Escenario = 1
            THEN v.Costos_Totales ELSE 0 END) AS costos_reales,

        SUM(CASE WHEN v.ID_Escenario = 2
            THEN v.Costos_Totales ELSE 0 END) AS costos_presupuesto,

        SUM(CASE WHEN v.ID_Escenario = 1
            THEN v.Margen_Bruto ELSE 0 END) AS margen_real,

        SUM(CASE WHEN v.ID_Escenario = 2
            THEN v.Margen_Bruto ELSE 0 END) AS margen_presupuesto

    FROM vw_finanzas_base v
    JOIN dim_unidades_negocio u
        ON v.ID_Unidad_Negocio = u.ID_Unidad_Negocio
    GROUP BY u.Division_ES
)
SELECT
    Division_ES,
    ROUND(ingresos_reales, 2) AS Ingresos_Reales,
    ROUND(margen_real, 2) AS Margen_Real,
    ROUND(margen_presupuesto, 2) AS Margen_Presupuesto,

    ROUND(
        ingresos_reales - ingresos_presupuesto, 2
    ) AS Desviacion_Ingresos,

    ROUND(
        costos_reales - costos_presupuesto, 2
    ) AS Desviacion_Costos,

    ROUND(
        margen_real - margen_presupuesto, 2
    ) AS Desviacion_Margen,

    ROUND(
        100 * (
            margen_real / NULLIF(ingresos_reales, 0)
            - margen_presupuesto / NULLIF(ingresos_presupuesto, 0)
        ), 2
    ) AS Brecha_Margen_pp

FROM resumen_divisiones
ORDER BY margen_real - margen_presupuesto ASC;

USE rentabilidad_clientes;

WITH resumen_unidades AS (
    SELECT
        u.ID_Unidad_Negocio,
        u.Unidad_Negocio,

        SUM(CASE WHEN v.ID_Escenario = 1
            THEN v.Ingresos ELSE 0 END) AS ingresos_reales,

        SUM(CASE WHEN v.ID_Escenario = 2
            THEN v.Ingresos ELSE 0 END) AS ingresos_presupuesto,

        SUM(CASE WHEN v.ID_Escenario = 1
            THEN v.Costos_Totales ELSE 0 END) AS costos_reales,

        SUM(CASE WHEN v.ID_Escenario = 2
            THEN v.Costos_Totales ELSE 0 END) AS costos_presupuesto,

        SUM(CASE WHEN v.ID_Escenario = 1
            THEN v.Margen_Bruto ELSE 0 END) AS margen_real,

        SUM(CASE WHEN v.ID_Escenario = 2
            THEN v.Margen_Bruto ELSE 0 END) AS margen_presupuesto

    FROM vw_finanzas_base v
    JOIN dim_unidades_negocio u
        ON v.ID_Unidad_Negocio = u.ID_Unidad_Negocio
    WHERE u.Division_ES = 'Principal'
    GROUP BY u.ID_Unidad_Negocio, u.Unidad_Negocio
)
SELECT
    ID_Unidad_Negocio,
    Unidad_Negocio,
    ROUND(ingresos_reales, 2) AS Ingresos_Reales,
    ROUND(margen_real, 2) AS Margen_Real,
    ROUND(margen_presupuesto, 2) AS Margen_Presupuesto,

    ROUND(
        ingresos_reales - ingresos_presupuesto, 2
    ) AS Desviacion_Ingresos,

    ROUND(
        costos_reales - costos_presupuesto, 2
    ) AS Desviacion_Costos,

    ROUND(
        margen_real - margen_presupuesto, 2
    ) AS Desviacion_Margen

FROM resumen_unidades
ORDER BY margen_real - margen_presupuesto ASC;

USE rentabilidad_clientes;

WITH base AS (
    SELECT *
    FROM fact_finanzas
    WHERE ID_Unidad_Negocio IN (48, 10)
),
costos_desglosados AS (
    SELECT ID_Unidad_Negocio, ID_Escenario,
           'Materiales' AS Tipo_Costo,
           COALESCE(Costos_Materiales, 0) AS Importe
    FROM base

    UNION ALL

    SELECT ID_Unidad_Negocio, ID_Escenario,
           'Mano de obra variable',
           COALESCE(Costos_Mano_Obra_Variable, 0)
    FROM base

    UNION ALL

    SELECT ID_Unidad_Negocio, ID_Escenario,
           'Impuestos',
           COALESCE(Impuestos, 0)
    FROM base

    UNION ALL

    SELECT ID_Unidad_Negocio, ID_Escenario,
           'Ingresos por gastos de viaje',
           COALESCE(Ingresos_por_Gastos_Viaje, 0)
    FROM base

    UNION ALL

    SELECT ID_Unidad_Negocio, ID_Escenario,
           'Gastos de viaje',
           COALESCE(Gastos_Viaje, 0)
    FROM base

    UNION ALL

    SELECT ID_Unidad_Negocio, ID_Escenario,
           'Costos de terceros',
           COALESCE(Costos_Terceros, 0)
    FROM base
),
resumen AS (
    SELECT
        ID_Unidad_Negocio,
        Tipo_Costo,
        SUM(CASE WHEN ID_Escenario = 1
            THEN Importe ELSE 0 END) AS Costo_Real,
        SUM(CASE WHEN ID_Escenario = 2
            THEN Importe ELSE 0 END) AS Costo_Presupuesto
    FROM costos_desglosados
    GROUP BY ID_Unidad_Negocio, Tipo_Costo
)
SELECT
    ID_Unidad_Negocio,
    Tipo_Costo,
    ROUND(Costo_Real, 2) AS Costo_Real,
    ROUND(Costo_Presupuesto, 2) AS Costo_Presupuesto,
    ROUND(
        Costo_Real - Costo_Presupuesto, 2
    ) AS Desviacion_Costo
FROM resumen
ORDER BY
    ID_Unidad_Negocio,
    Costo_Real - Costo_Presupuesto DESC;
    
    USE rentabilidad_clientes;

WITH resumen_mensual AS (
    SELECT
        Anio_Periodo,

        SUM(CASE WHEN ID_Escenario = 1
            THEN Ingresos ELSE 0 END) AS ingresos_reales,

        SUM(CASE WHEN ID_Escenario = 2
            THEN Ingresos ELSE 0 END) AS ingresos_presupuesto,

        SUM(CASE WHEN ID_Escenario = 1
            THEN Costos_Totales ELSE 0 END) AS costos_reales,

        SUM(CASE WHEN ID_Escenario = 2
            THEN Costos_Totales ELSE 0 END) AS costos_presupuesto,

        SUM(CASE WHEN ID_Escenario = 1
            THEN Margen_Bruto ELSE 0 END) AS margen_real,

        SUM(CASE WHEN ID_Escenario = 2
            THEN Margen_Bruto ELSE 0 END) AS margen_presupuesto

    FROM vw_finanzas_base
    GROUP BY Anio_Periodo
)
SELECT
    Anio_Periodo,
    ROUND(ingresos_reales, 2) AS Ingresos_Reales,
    ROUND(ingresos_presupuesto, 2) AS Ingresos_Presupuesto,

    ROUND(
        ingresos_reales - ingresos_presupuesto, 2
    ) AS Desviacion_Ingresos,

    ROUND(
        costos_reales - costos_presupuesto, 2
    ) AS Desviacion_Costos,

    ROUND(margen_real, 2) AS Margen_Real,
    ROUND(margen_presupuesto, 2) AS Margen_Presupuesto,

    ROUND(
        margen_real - margen_presupuesto, 2
    ) AS Desviacion_Margen

FROM resumen_mensual
ORDER BY Anio_Periodo;

USE rentabilidad_clientes;

WITH resumen_clientes AS (
    SELECT
        c.ID_Cliente,
        c.Nombre_Cliente,
        c.Estado_Catalogo_Cliente,

        SUM(CASE WHEN v.ID_Escenario = 1
            THEN v.Ingresos ELSE 0 END) AS ingresos_reales,

        SUM(CASE WHEN v.ID_Escenario = 1
            THEN v.Margen_Bruto ELSE 0 END) AS margen_real,

        SUM(CASE WHEN v.ID_Escenario = 2
            THEN v.Margen_Bruto ELSE 0 END) AS margen_presupuesto

    FROM vw_finanzas_base v
    JOIN dim_clientes c
        ON v.ID_Cliente = c.ID_Cliente
    GROUP BY
        c.ID_Cliente,
        c.Nombre_Cliente,
        c.Estado_Catalogo_Cliente
)
SELECT
    ID_Cliente,
    Nombre_Cliente,
    Estado_Catalogo_Cliente,
    ROUND(ingresos_reales, 2) AS Ingresos_Reales,
    ROUND(margen_real, 2) AS Margen_Bruto_Real,

    CASE
        WHEN ABS(ingresos_reales) < 0.005 THEN NULL
        ELSE ROUND(
            100 * margen_real / NULLIF(ingresos_reales, 0),
            2
        )
    END AS Margen_Real_Porcentaje,

    ROUND(margen_presupuesto, 2) AS Margen_Presupuesto,

    ROUND(
        margen_real - margen_presupuesto, 2
    ) AS Desviacion_Margen

FROM resumen_clientes
ORDER BY margen_real DESC, ID_Cliente
LIMIT 10;

USE rentabilidad_clientes;

WITH resumen_clientes AS (
    SELECT
        c.ID_Cliente,
        c.Nombre_Cliente,
        c.Estado_Catalogo_Cliente,

        SUM(CASE WHEN v.ID_Escenario = 1
            THEN v.Ingresos ELSE 0 END) AS ingresos_reales,

        SUM(CASE WHEN v.ID_Escenario = 1
            THEN v.Margen_Bruto ELSE 0 END) AS margen_real,

        SUM(CASE WHEN v.ID_Escenario = 2
            THEN v.Margen_Bruto ELSE 0 END) AS margen_presupuesto

    FROM vw_finanzas_base v
    JOIN dim_clientes c
        ON v.ID_Cliente = c.ID_Cliente
    GROUP BY
        c.ID_Cliente,
        c.Nombre_Cliente,
        c.Estado_Catalogo_Cliente
)
SELECT
    ID_Cliente,
    Nombre_Cliente,
    Estado_Catalogo_Cliente,
    ROUND(ingresos_reales, 2) AS Ingresos_Reales,
    ROUND(margen_real, 2) AS Margen_Bruto_Real,

    CASE
        WHEN ABS(ingresos_reales) < 0.005 THEN NULL
        ELSE ROUND(
            100 * margen_real / NULLIF(ingresos_reales, 0),
            2
        )
    END AS Margen_Real_Porcentaje,

    ROUND(
        margen_real - margen_presupuesto, 2
    ) AS Desviacion_Margen

FROM resumen_clientes
WHERE margen_real < 0
ORDER BY margen_real ASC, ID_Cliente;

USE rentabilidad_clientes;

WITH resumen_catalogo AS (
    SELECT
        c.Estado_Catalogo_Cliente,

        COUNT(DISTINCT CASE
            WHEN v.ID_Escenario = 1 THEN v.ID_Cliente
        END) AS clientes_con_registros_reales,

        SUM(CASE WHEN v.ID_Escenario = 1
            THEN v.Ingresos ELSE 0 END) AS ingresos_reales,

        SUM(CASE WHEN v.ID_Escenario = 1
            THEN v.Margen_Bruto ELSE 0 END) AS margen_real,

        SUM(CASE WHEN v.ID_Escenario = 2
            THEN v.Margen_Bruto ELSE 0 END) AS margen_presupuesto

    FROM vw_finanzas_base v
    JOIN dim_clientes c
        ON v.ID_Cliente = c.ID_Cliente
    GROUP BY c.Estado_Catalogo_Cliente
)
SELECT
    Estado_Catalogo_Cliente,
    clientes_con_registros_reales AS Clientes_Con_Registros_Reales,
    ROUND(ingresos_reales, 2) AS Ingresos_Reales,
    ROUND(margen_real, 2) AS Margen_Bruto_Real,

    CASE
        WHEN ABS(ingresos_reales) < 0.005 THEN NULL
        ELSE ROUND(
            100 * margen_real / NULLIF(ingresos_reales, 0),
            2
        )
    END AS Margen_Real_Porcentaje,

    ROUND(
        margen_real - margen_presupuesto, 2
    ) AS Desviacion_Margen,

    ROUND(
        100 * ingresos_reales
        / NULLIF(SUM(ingresos_reales) OVER (), 0),
        2
    ) AS Participacion_Ingresos_Porcentaje

FROM resumen_catalogo
ORDER BY Estado_Catalogo_Cliente;