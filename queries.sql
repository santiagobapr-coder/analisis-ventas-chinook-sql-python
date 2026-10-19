-- Análisis de ventas de Chinook (tienda de música). Motor: SQLite.
-- Cada consulta está separada por una línea "-- name: <nombre>" para que analysis.py las ejecute por nombre.

-- name: ingresos_por_anio
-- ¿Cuánto se vendió por año y cuánto crecieron los ingresos respecto al año anterior?
WITH anual AS (
    SELECT strftime('%Y', InvoiceDate) AS anio,
           COUNT(*)                    AS facturas,
           ROUND(SUM(Total), 2)        AS ingresos
    FROM Invoice
    GROUP BY anio
)
SELECT anio,
       facturas,
       ingresos,
       ROUND(100.0 * (ingresos - LAG(ingresos) OVER (ORDER BY anio))
             / LAG(ingresos) OVER (ORDER BY anio), 1) AS crecimiento_pct
FROM anual
ORDER BY anio;

-- name: top_paises
-- ¿Qué países generan más ingresos y cuál es su ticket promedio?
SELECT BillingCountry                 AS pais,
       COUNT(DISTINCT CustomerId)     AS clientes,
       COUNT(*)                       AS facturas,
       ROUND(SUM(Total), 2)           AS ingresos,
       ROUND(AVG(Total), 2)           AS ticket_promedio
FROM Invoice
GROUP BY BillingCountry
ORDER BY ingresos DESC
LIMIT 10;

-- name: top_clientes
-- ¿Quiénes son los 10 clientes que más gastan?
SELECT c.FirstName || ' ' || c.LastName AS cliente,
       c.Country                        AS pais,
       COUNT(i.InvoiceId)               AS compras,
       ROUND(SUM(i.Total), 2)           AS gasto_total
FROM Customer c
JOIN Invoice i ON i.CustomerId = c.CustomerId
GROUP BY c.CustomerId
ORDER BY gasto_total DESC
LIMIT 10;

-- name: ingresos_por_genero
-- ¿Qué géneros musicales generan más ingresos?
SELECT g.Name                                      AS genero,
       ROUND(SUM(il.UnitPrice * il.Quantity), 2)   AS ingresos,
       SUM(il.Quantity)                            AS unidades,
       ROUND(100.0 * SUM(il.UnitPrice * il.Quantity)
             / (SELECT SUM(UnitPrice * Quantity) FROM InvoiceLine), 1) AS participacion_pct
FROM InvoiceLine il
JOIN Track t ON t.TrackId = il.TrackId
JOIN Genre g ON g.GenreId = t.GenreId
GROUP BY g.GenreId
ORDER BY ingresos DESC
LIMIT 10;

-- name: top_artistas
-- ¿Qué artistas venden más?
SELECT ar.Name                                     AS artista,
       ROUND(SUM(il.UnitPrice * il.Quantity), 2)   AS ingresos,
       SUM(il.Quantity)                            AS unidades
FROM InvoiceLine il
JOIN Track  t  ON t.TrackId  = il.TrackId
JOIN Album  al ON al.AlbumId = t.AlbumId
JOIN Artist ar ON ar.ArtistId = al.ArtistId
GROUP BY ar.ArtistId
ORDER BY ingresos DESC
LIMIT 10;

-- name: desempeno_representantes
-- ¿Cuántos ingresos generan los clientes que atiende cada representante de soporte?
SELECT e.FirstName || ' ' || e.LastName AS representante,
       COUNT(DISTINCT c.CustomerId)     AS clientes,
       ROUND(SUM(i.Total), 2)           AS ingresos,
       ROUND(SUM(i.Total) / COUNT(DISTINCT c.CustomerId), 2) AS ingresos_por_cliente
FROM Employee e
JOIN Customer c ON c.SupportRepId = e.EmployeeId
JOIN Invoice  i ON i.CustomerId   = c.CustomerId
GROUP BY e.EmployeeId
ORDER BY ingresos DESC;

-- name: ingresos_por_formato
-- ¿Qué formato de archivo (tipo de medio) concentra las ventas?
SELECT m.Name                                      AS formato,
       ROUND(SUM(il.UnitPrice * il.Quantity), 2)   AS ingresos,
       SUM(il.Quantity)                            AS unidades,
       ROUND(100.0 * SUM(il.UnitPrice * il.Quantity)
             / (SELECT SUM(UnitPrice * Quantity) FROM InvoiceLine), 1) AS participacion_pct
FROM InvoiceLine il
JOIN Track     t ON t.TrackId     = il.TrackId
JOIN MediaType m ON m.MediaTypeId = t.MediaTypeId
GROUP BY m.MediaTypeId
ORDER BY ingresos DESC;
