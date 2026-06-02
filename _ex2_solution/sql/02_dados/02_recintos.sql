-- Exercício 2.2 — Recintos
-- Cada zona fica com 12 recintos.
-- Isto satisfaz o intervalo exigido: entre 10 e 30 recintos por zona.
-- Os votos são inicializados a 0 e atualizados após a criação dos bilhetes.

INSERT INTO recinto (id_zona, votos)
SELECT z.id_zona, 0
FROM zona z
CROSS JOIN generate_series(1, 12) AS g(n)
ORDER BY z.id_zona, g.n;
