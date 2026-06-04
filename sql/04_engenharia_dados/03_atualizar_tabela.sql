%%sql zoo
WITH receita_por_zona AS (
    -- Calcula a receita total acumulada de cada zona usando a vista do ponto 1
    SELECT 
        id_zona,
        SUM(receita) AS receita_total_zona
    FROM vendas_zoo
    GROUP BY id_zona
),
votos_por_zona AS (
    -- Calcula o total de votos que cada zona recebeu somando os seus recintos
    SELECT 
        id_zona,
        SUM(votos) AS total_votos_zona
    FROM recinto
    GROUP BY id_zona
),
plano_rentabilidade AS (
    -- Aplica a fórmula: Receita da Zona * (Votos do Recinto / Total de Votos da Zona)
    SELECT 
        r.id_recinto,
        (rz.receita_total_zona * (r.votos * 1.0 / NULLIF(vz.total_votos_zona, 0)))::REAL AS rentabilidade_calculada
    FROM recinto r
    JOIN receita_por_zona rz ON r.id_zona = rz.id_zona
    JOIN votos_por_zona vz ON r.id_zona = vz.id_zona
)
-- Atualiza a tabela física de recintos com os valores calculados
UPDATE recinto r
SET rentabilidade = p.rentabilidade_calculada
FROM plano_rentabilidade p
WHERE r.id_recinto = p.id_recinto;