%%sql 

SELECT
  dia_da_semana,
  mes,
  ROUND(
    COUNT(CASE WHEN zonas_acessadas = (SELECT COUNT(*) FROM zona) THEN 1 END) * 100.0 / COUNT(*),
    2
  ) AS percentagem_acesso_total
FROM (
  -- Agrupar por bilhete
  SELECT
    bid,
    mes,
    dia_da_semana,
    COUNT(id_zona) AS zonas_acessadas
  FROM vendas_zoo
  GROUP BY bid, mes, dia_da_semana
) AS contagem_zonas
GROUP BY
  GROUPING SETS (
    (),               -- Global
    (dia_da_semana),  -- Drill-down independente por dia da semana
    (mes)             -- Drill-down independente por mês
  )
ORDER BY
  mes, dia_da_semana;
