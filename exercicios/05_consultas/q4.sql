%%sql zoo

SELECT
  id_zona,
  mes,
  ROUND(COUNT(DISTINCT bid) * 1.0 / COUNT(DISTINCT data), 2) AS media_diaria_bilhetes,
  CASE
    WHEN (COUNT(DISTINCT bid) * 1.0 / COUNT(DISTINCT data)) > (SELECT COUNT(DISTINCT bid) * 1.0 / COUNT(DISTINCT data) FROM vendas_zoo) THEN 'Aumentar Preço'
    WHEN (COUNT(DISTINCT bid) * 1.0 / COUNT(DISTINCT data)) < (SELECT COUNT(DISTINCT bid) * 1.0 / COUNT(DISTINCT data) FROM vendas_zoo) THEN 'Reduzir Preço'
    ELSE 'Manter Preço'
  END AS recomendacao
FROM
  vendas_zoo
GROUP BY
  CUBE (id_zona, mes)
ORDER BY
  id_zona, mes;

