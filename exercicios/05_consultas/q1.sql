%%sql zoo
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