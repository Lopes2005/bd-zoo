%%sql
-- Criação do índice recomendado para tornar a RI-4 "instantânea"
CREATE INDEX IF NOT EXISTS idx_bilhete_no_venda ON bilhete(no_venda);

BEGIN;

 
CREATE TEMP TABLE _ticket_plan ON COMMIT DROP AS
-- Gerar os dias entre 2026-01-01 e 2026-06-11,  1000 bilhetes para dias úteis e 4000 para fds
WITH dias AS ( 
    SELECT
        d::DATE AS data,
        CASE
            WHEN EXTRACT(ISODOW FROM d) IN (6, 7) THEN 4000
            ELSE 1000
        END AS n_bilhetes
    FROM generate_series(
        DATE '2026-01-01',
        DATE '2026-06-11',
        INTERVAL '1 day'
    ) AS gs(d)
),--- Gerar os bilhetes para cada dia, numerando-os de 1 a n_bilhetes
base AS (
    SELECT
        d.data,
        d.n_bilhetes,
        g.n AS bilhete_no_dia
    FROM dias d
    CROSS JOIN LATERAL generate_series(1, d.n_bilhetes) AS g(n)
),--- Adicionar uma numeração global aos bilhetes, ordenada por data e número do bilhete no dia
numerada AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY data, bilhete_no_dia) AS ticket_seq,
        data,
        n_bilhetes,
        bilhete_no_dia
    FROM base
)
SELECT --- Gerar os dados finais para cada bilhete, incluindo data_hora, nif_cliente, desconto e voto
    ticket_seq,
    data,
    n_bilhetes,
    bilhete_no_dia,
    data
        + TIME '09:00'
        + ((bilhete_no_dia % 10) * INTERVAL '1 hour')
        + ((bilhete_no_dia % 60) * INTERVAL '1 minute') AS data_hora,
    LPAD((100000000 + ticket_seq)::TEXT, 9, '0') AS nif_cliente,
    CASE
        WHEN bilhete_no_dia % 2 = 0 THEN 0.50::NUMERIC(4,2)
        ELSE 0.00::NUMERIC(4,2)
    END AS desconto,
    (bilhete_no_dia % 4 <> 0) AS votou
FROM numerada;

-- Inserir os dados gerados nas tabelas venda e bilhete, garantindo que as relações entre elas sejam mantidas
INSERT INTO venda (data_hora, nif_cliente)
SELECT data_hora, nif_cliente
FROM _ticket_plan
ORDER BY ticket_seq;

-- O número do bilhete (bid) é gerado automaticamente, 
-- e o no_venda é associado com base na ordem de inserção
INSERT INTO bilhete (desconto, votou, no_venda)
SELECT
    p.desconto,
    p.votou,
    v.no_venda
FROM _ticket_plan p
JOIN venda v
  ON v.nif_cliente = p.nif_cliente
ORDER BY p.ticket_seq;

-- Gerar os acessos para cada bilhete, garantindo que 2% dos bilhetes tenham acesso a todas as zonas 
-- e os restantes sejam distribuídos de forma equilibrada pelos combos de zonas
CREATE TEMP TABLE _zona_ord ON COMMIT DROP AS
SELECT
    id_zona,
    ROW_NUMBER() OVER (ORDER BY id_zona) - 1 AS idx
FROM zona
ORDER BY id_zona;

-- Gerar todas as combinações possíveis de zonas (exceto a combinação vazia) 
-- e filtrar apenas as combinações válidas (com pelo menos 3 zonas)
CREATE TEMP TABLE _combo ON COMMIT DROP AS
WITH n AS (
    SELECT COUNT(*)::INTEGER AS n_zonas FROM _zona_ord
),
masks AS (
    SELECT generate_series(1, (POWER(2, n_zonas)::INTEGER) - 1) AS mask
    FROM n
),
validas AS (
    SELECT m.mask
    FROM masks m
    JOIN _zona_ord z
      ON (m.mask & (POWER(2, z.idx)::INTEGER)) <> 0
    GROUP BY m.mask
    HAVING COUNT(*) >= 3
)
SELECT
    ROW_NUMBER() OVER (ORDER BY mask) AS combo_idx,
    mask
FROM validas;

-- Criar uma tabela temporária para mapear cada combo de zonas às zonas correspondentes, 
-- facilitando a atribuição de acessos
CREATE TEMP TABLE _combo_zona ON COMMIT DROP AS
SELECT
    c.combo_idx,
    z.id_zona
FROM _combo c
JOIN _zona_ord z
  ON (c.mask & (POWER(2, z.idx)::INTEGER)) <> 0;

-- Inserir os acessos para cada bilhete, garantindo que 2% dos bilhetes tenham acesso a todas as zonas
INSERT INTO acesso (bid, id_zona)
SELECT
    b.bid,
    z.id_zona
FROM _ticket_plan p
JOIN venda v
  ON v.nif_cliente = p.nif_cliente
JOIN bilhete b
  ON b.no_venda = v.no_venda
JOIN _zona_ord z
  ON TRUE
WHERE p.bilhete_no_dia <= CEIL(p.n_bilhetes * 0.02)

UNION ALL

-- Para os restantes bilhetes, atribuir acessos com base nos combos de zonas,
--  garantindo uma distribuição equilibrada
SELECT
    b.bid,
    cz.id_zona
FROM _ticket_plan p
JOIN venda v
  ON v.nif_cliente = p.nif_cliente
JOIN bilhete b
  ON b.no_venda = v.no_venda
CROSS JOIN (SELECT COUNT(*) AS total_combos FROM _combo) tc 
JOIN _combo c
  ON c.combo_idx = 1 + ((p.ticket_seq - 1) % tc.total_combos)
JOIN _combo_zona cz
  ON cz.combo_idx = c.combo_idx
WHERE p.bilhete_no_dia > CEIL(p.n_bilhetes * 0.02);

-- Calcular o número de votos para cada recinto, distribuindo os votos de forma equilibrada entre os recintos
WITH parametros AS (
    SELECT COUNT(*)::INTEGER AS total_votos
    FROM bilhete
    WHERE votou
),
recintos AS (
    SELECT
        id_recinto,
        ROW_NUMBER() OVER (ORDER BY id_recinto)::INTEGER AS rn,
        COUNT(*) OVER ()::INTEGER AS n_recintos
    FROM recinto
),
plano AS (
    SELECT
        r.id_recinto,
        (p.total_votos / r.n_recintos)
        + CASE
            WHEN r.rn <= (p.total_votos % r.n_recintos) THEN 1
            ELSE 0
          END AS votos_calculados
    FROM recintos r
    CROSS JOIN parametros p
)
UPDATE recinto r
SET votos = p.votos_calculados
FROM plano p
WHERE p.id_recinto = r.id_recinto;


-- Forçar o Postgres a ver o tamanho real das tabelas
-- Isto garante que o Query Planner use o index nos triggers deferred 
ANALYZE venda;
ANALYZE bilhete;
ANALYZE acesso;

COMMIT;