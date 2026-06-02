-- Exercício 2.4 — Animais
-- Estratégia:
--   1) cada espécie é colocada numa zona compatível, preferindo zona exacta
--      (categoria+continente), depois zona de categoria, depois zona de continente;
--   2) todos os animais da mesma espécie ficam numa única zona, satisfazendo RI-3;
--   3) cada espécie tem 1, 2 ou 3 animais, logo a média fica entre 2 e 3;
--   4) reserva-se o primeiro recinto de cada zona para uma espécie com 1 animal,
--      garantindo recintos com apenas um animal;
--   5) as restantes espécies são distribuídas pelos outros recintos da zona,
--      criando recintos com vários animais da mesma espécie e recintos com várias espécies.

WITH zona_ordenada AS (
    SELECT
        r.id_recinto,
        r.id_zona,
        ROW_NUMBER() OVER (
            PARTITION BY r.id_zona
            ORDER BY r.id_recinto
        ) AS pos_recinto
    FROM recinto r
),
especie_com_zona AS (
    SELECT
        e.nome_cientifico,
        e.categoria,
        e.continente,
        COALESCE(
            (
                SELECT z.id_zona
                FROM zona z
                WHERE z.categoria = e.categoria
                  AND z.continente = e.continente
                LIMIT 1
            ),
            (
                SELECT z.id_zona
                FROM zona z
                WHERE z.categoria = e.categoria
                  AND z.continente IS NULL
                LIMIT 1
            ),
            (
                SELECT z.id_zona
                FROM zona z
                WHERE z.categoria IS NULL
                  AND z.continente = e.continente
                LIMIT 1
            )
        ) AS id_zona
    FROM especie e
),
especie_planeada AS (
    SELECT
        ez.*,
        ROW_NUMBER() OVER (
            PARTITION BY ez.id_zona
            ORDER BY ez.nome_cientifico
        ) AS pos_especie_na_zona
    FROM especie_com_zona ez
),
especie_com_recinto AS (
    SELECT
        ep.nome_cientifico,
        zr.id_recinto,
        CASE
            WHEN ep.pos_especie_na_zona = 1 THEN 1
            WHEN ep.pos_especie_na_zona % 10 = 0 THEN 3
            ELSE 2
        END AS n_animais
    FROM especie_planeada ep
    JOIN zona_ordenada zr
      ON zr.id_zona = ep.id_zona
     AND zr.pos_recinto =
         CASE
             WHEN ep.pos_especie_na_zona = 1 THEN 1
             ELSE 2 + ((ep.pos_especie_na_zona - 2) % 11)
         END
)
INSERT INTO animal (nome, nome_cientifico, id_recinto, data_nasc)
SELECT
    'Animal ' || g.n AS nome,
    er.nome_cientifico,
    er.id_recinto,
    DATE '2015-01-01'
        + ((ROW_NUMBER() OVER (ORDER BY er.nome_cientifico, g.n))::INTEGER % 3500)
FROM especie_com_recinto er
CROSS JOIN LATERAL generate_series(1, er.n_animais) AS g(n)
ORDER BY er.nome_cientifico, g.n;
