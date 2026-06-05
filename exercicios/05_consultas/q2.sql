%%sql zoo
WITH analise_por_zona AS (
    -- Agregar as receitas a partir da vista materializada
    SELECT 
        id_zona,
        SUM(receita) AS receita_zona
    FROM vendas_zoo
    GROUP BY id_zona
),
dados_consolidados AS (
    -- Cruzar com a tabela zona e injetar a tua regra do Exercício 2.1 (África)
    SELECT 
        z.id_zona,
        -- Aplica a lógica: se for África, é da especialidade!
        CASE 
            WHEN z.continente = 'África' THEN TRUE 
            ELSE FALSE 
        END AS da_especialidade,
        COALESCE(az.receita_zona, 0) AS receita_zona,
        -- Contagem precisa de bilhetes reais usando a tabela acesso
        (SELECT COUNT(DISTINCT a.bid) FROM acesso a WHERE a.id_zona = z.id_zona) AS bilhetes_zona,
        -- Soma dos votos dos recintos daquela zona
        COALESCE((SELECT SUM(votos) FROM recinto r WHERE r.id_zona = z.id_zona), 0) AS votos_zona
    FROM zona z
    LEFT JOIN analise_por_zona az ON z.id_zona = az.id_zona
)
-- Gerar a tabela analítica final com médias e o operador CUBE
SELECT 
    CASE 
        WHEN da_especialidade IS TRUE THEN 'Zonas da Especialidade (África)'
        WHEN da_especialidade IS FALSE THEN 'Outras Zonas'
        ELSE 'Total Geral do Zoo (Média por Grupo)'
    END AS tipo_de_zona,
    ROUND(AVG(receita_zona), 2) AS media_receita,
    ROUND(AVG(bilhetes_zona), 0) AS media_bilhetes_vendidos,
    ROUND(AVG(votos_zona), 0) AS media_votos_recebidos
FROM dados_consolidados
GROUP BY CUBE(da_especialidade)
ORDER BY da_especialidade DESC NULLS LAST;