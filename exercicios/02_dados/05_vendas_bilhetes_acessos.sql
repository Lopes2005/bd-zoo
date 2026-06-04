%%sql 
-- Exercício 2.5 — Vendas, bilhetes, acessos e votos
-- Este bloco usa uma única transação porque a RI-4 exige que venda,
-- bilhete e acesso formem uma unidade lógica completa.
-- A aula de transações justifica este padrão: várias instruções SQL
-- que representam uma operação lógica devem ser envolvidas por BEGIN/COMMIT.

BEGIN;

-- Plano determinístico de bilhetes:
--   dias úteis: 1000 bilhetes;
--   fins de semana: 4000 bilhetes;
--   50% com desconto 0.50 e 50% com desconto 0.00;
--   75% com votou TRUE;
--   NIF sintético e único para permitir ligar vendas ao plano.
CREATE TEMP TABLE _ticket_plan ON COMMIT DROP AS
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
),
base AS (
    SELECT
        d.data,
        d.n_bilhetes,
        g.n AS bilhete_no_dia
    FROM dias d
    CROSS JOIN LATERAL generate_series(1, d.n_bilhetes) AS g(n)
),
numerada AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY data, bilhete_no_dia) AS ticket_seq,
        data,
        n_bilhetes,
        bilhete_no_dia
    FROM base
)
SELECT
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

-- Uma venda por bilhete. Isto simplifica a prova da RI-4:
-- cada venda fica associada a um bilhete que terá acessos.
INSERT INTO venda (data_hora, nif_cliente)
SELECT data_hora, nif_cliente
FROM _ticket_plan
ORDER BY ticket_seq;

INSERT INTO bilhete (desconto, votou, no_venda)
SELECT
    p.desconto,
    p.votou,
    v.no_venda
FROM _ticket_plan p
JOIN venda v
  ON v.nif_cliente = p.nif_cliente
ORDER BY p.ticket_seq;

-- Tabela auxiliar de zonas numeradas.
CREATE TEMP TABLE _zona_ord ON COMMIT DROP AS
SELECT
    id_zona,
    ROW_NUMBER() OVER (ORDER BY id_zona) - 1 AS idx
FROM zona
ORDER BY id_zona;

-- Todas as combinações de 3 ou mais zonas.
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

CREATE TEMP TABLE _combo_zona ON COMMIT DROP AS
SELECT
    c.combo_idx,
    z.id_zona
FROM _combo c
JOIN _zona_ord z
  ON (c.mask & (POWER(2, z.idx)::INTEGER)) <> 0;

-- Acessos:
--   pelo menos 2% dos bilhetes de cada dia têm acesso total;
--   os restantes percorrem ciclicamente todas as combinações de 3+ zonas.
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

SELECT
    b.bid,
    cz.id_zona
FROM _ticket_plan p
JOIN venda v
  ON v.nif_cliente = p.nif_cliente
JOIN bilhete b
  ON b.no_venda = v.no_venda
JOIN _combo c
  ON c.combo_idx = 1 + ((p.ticket_seq - 1) % (SELECT COUNT(*) FROM _combo))
JOIN _combo_zona cz
  ON cz.combo_idx = c.combo_idx
WHERE p.bilhete_no_dia > CEIL(p.n_bilhetes * 0.02);

-- Atualização dos votos:
--   soma global dos votos = número de bilhetes com votou TRUE;
--   distribuição quase uniforme por recinto;
--   cada recinto recebe muito mais do que 0.1% dos votos totais
--   dado o volume mínimo de bilhetes exigido.
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

COMMIT;
