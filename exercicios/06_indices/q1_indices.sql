EXPLAIN (ANALYZE, BUFFERS, MEMORY, SERIALIZE)
WITH ranking_recintos AS (
    SELECT 
        id_zona,
        id_recinto,
        rentabilidade,
        ROW_NUMBER() OVER (PARTITION BY id_zona ORDER BY rentabilidade DESC, id_recinto ASC) AS pos
    FROM recinto
)
SELECT 
    id_zona,
    id_recinto,
    rentabilidade
FROM ranking_recintos
WHERE pos = 1
ORDER BY id_zona;



CREATE INDEX IF NOT EXISTS idx_recinto_zona_rentabilidade
ON recinto (id_zona, rentabilidade DESC);




Foi criado o índice composto idx_recinto_zona_rentabilidade ON recinto(id_zona, rentabilidade DESC) porque a Consulta 1 procura o recinto de maior rentabilidade dentro de cada zona. A ordem dos atributos no índice segue a estrutura da consulta: primeiro agrupa-se/particiona-se por id_zona e depois ordena-se por rentabilidade DESC. Esta escolha é coerente com a teoria dos índices B-tree, que suportam igualdade, ordenação e chaves compostas. Contudo, o EXPLAIN ANALYSE mostrou que o PostgreSQL continuou a usar Seq Scan e Sort, em vez de Index Scan. Isto acontece porque a tabela recinto tem apenas cerca de 120 linhas, sendo mais barato percorrê-la sequencialmente do que aceder ao índice. Assim, o índice é teoricamente adequado, mas o ganho prático nesta instância é reduzido; a melhoria de tempo observada deve ser interpretada com cautela, pois pode resultar também de cache e de diferenças de planeamento. Mantemos o índice como uma otimização simples e não excessiva para consultas recorrentes deste tipo, mas reconhecemos que o seu impacto atual é limitado.