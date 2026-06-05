%%sql zoo
-- Garante que não há transações presas de execuções anteriores
ROLLBACK;

-- Limpa o lixo das tentativas anteriores para não duplicar dados
TRUNCATE TABLE acesso, bilhete, venda RESTART IDENTITY CASCADE;

-- [A TUA IDEIA]: Criar o índice para acelerar drasticamente os JOINs por no_venda
CREATE INDEX IF NOT EXISTS idx_bilhete_no_venda ON bilhete(no_venda);

BEGIN;

-- 1. Desativar temporariamente os triggers de utilizador para Bulk Load
ALTER TABLE acesso DISABLE TRIGGER USER;
ALTER TABLE bilhete DISABLE TRIGGER USER;
ALTER TABLE venda DISABLE TRIGGER USER;

-- 2. Criar plano determinístico de bilhetes (Substituído % por MOD)
DROP TABLE IF EXISTS _ticket_plan CASCADE;
CREATE TEMP TABLE _ticket_plan ON COMMIT DROP AS
WITH dias AS (
    SELECT
        CAST(d AS DATE) AS data,
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
        + (MOD(bilhete_no_dia, 10) * INTERVAL '1 hour')
        + (MOD(bilhete_no_dia, 60) * INTERVAL '1 minute') AS data_hora,
    LPAD(CAST(100000000 + ticket_seq AS TEXT), 9, '0') AS nif_cliente,
    CAST(CASE
        WHEN MOD(bilhete_no_dia, 2) = 0 THEN 0.50
        ELSE 0.00
    END AS NUMERIC(4,2)) AS desconto,
    (MOD(bilhete_no_dia, 4) <> 0) AS votou
FROM numerada;

-- 3. Inserir as Vendas
INSERT INTO venda (data_hora, nif_cliente)
SELECT data_hora, nif_cliente
FROM _ticket_plan
ORDER BY ticket_seq;

-- 4. Inserir os Bilhetes (Beneficia imediatamente do índice)
INSERT INTO bilhete (desconto, votou, no_venda)
SELECT
    p.desconto,
    p.votou,
    v.no_venda
FROM _ticket_plan p
JOIN venda v ON v.nif_cliente = p.nif_cliente
ORDER BY p.ticket_seq;

-- 5. Tabela auxiliar de zonas numeradas
DROP TABLE IF EXISTS _zona_ord CASCADE;
CREATE TEMP TABLE _zona_ord ON COMMIT DROP AS
SELECT
    id_zona,
    ROW_NUMBER() OVER (ORDER BY id_zona) - 1 AS idx
FROM zona
ORDER BY id_zona;

-- 6. Gerar todas as combinações de 3 ou mais zonas
DROP TABLE IF EXISTS _combo CASCADE;
CREATE TEMP TABLE _combo ON COMMIT DROP AS
WITH n AS (
    SELECT CAST(COUNT(*) AS INTEGER) AS n_zonas FROM _zona_ord
),
masks AS (
    SELECT generate_series(1, CAST(POWER(2, n.n_zonas) AS INTEGER) - 1) AS mask
    FROM n
),
validas AS (
    SELECT m.mask
    FROM masks m
    JOIN _zona_ord z ON (m.mask & CAST(POWER(2, z.idx) AS INTEGER)) <> 0
    GROUP BY m.mask
    HAVING COUNT(*) >= 3
)
SELECT
    ROW_NUMBER() OVER (ORDER BY mask) AS combo_idx,
    mask
FROM validas;

-- 7. Mapear os combos para as respetivas zonas
DROP TABLE IF EXISTS _combo_zona CASCADE;
CREATE TEMP TABLE _combo_zona ON COMMIT DROP AS
SELECT
    c.combo_idx,
    z.id_zona
FROM _combo c
JOIN _zona_ord z ON (c.mask & CAST(POWER(2, z.idx) AS INTEGER)) <> 0;

-- 8. Inserir os Acessos (Substituído % por MOD)
INSERT INTO acesso (bid, id_zona)
SELECT
    b.bid,
    z.id_zona
FROM _ticket_plan p
JOIN venda v ON v.nif_cliente = p.nif_cliente
JOIN bilhete b ON b.no_venda = v.no_venda
JOIN _zona_ord z ON TRUE
WHERE p.bilhete_no_dia <= CEIL(p.n_bilhetes * 0.02)

UNION ALL

SELECT
    b.bid,
    cz.id_zona
FROM _ticket_plan p
JOIN venda v ON v.nif_cliente = p.nif_cliente
JOIN bilhete b ON b.no_venda = v.no_venda
CROSS JOIN (SELECT COUNT(*) AS total_combos FROM _combo) tc 
JOIN _combo c ON c.combo_idx = 1 + (MOD(CAST(p.ticket_seq - 1 AS INTEGER), CAST(tc.total_combos AS INTEGER)))
JOIN _combo_zona cz ON cz.combo_idx = c.combo_idx
WHERE p.bilhete_no_dia > CEIL(p.n_bilhetes * 0.02);

-- 9. Atualizar os votos (Substituído % por MOD)
WITH parametros AS (
    SELECT CAST(COUNT(*) AS INTEGER) AS total_votos
    FROM bilhete
    WHERE votou
),
recintos AS (
    SELECT
        id_recinto,
        CAST(ROW_NUMBER() OVER (ORDER BY id_recinto) AS INTEGER) AS rn,
        CAST(COUNT(*) OVER () AS INTEGER) AS n_recintos
    FROM recinto
),
plano AS (
    SELECT
        r.id_recinto,
        (p.total_votos / r.n_recintos)
        + CASE
            WHEN r.rn <= MOD(p.total_votos, r.n_recintos) THEN 1
            ELSE 0
          END AS votos_calculados
    FROM recintos r
    CROSS JOIN parametros p
)
UPDATE recinto r
SET votos = p.votos_calculados
FROM plano p
WHERE p.id_recinto = r.id_recinto;

-- 10. Reativar os triggers de validação
ALTER TABLE venda ENABLE TRIGGER USER;
ALTER TABLE bilhete ENABLE TRIGGER USER;
ALTER TABLE acesso ENABLE TRIGGER USER;

-- 11. Validação global da RI-4
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM venda v
        WHERE NOT EXISTS (
            SELECT 1
            FROM bilhete b
            JOIN acesso a ON a.bid = b.bid
            WHERE b.no_venda = v.no_venda
        )
    ) THEN
        RAISE EXCEPTION 'RI-4 violada durante o preenchimento massivo.';
    END IF;
END $$;

COMMIT;