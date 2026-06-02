-- Validações do Exercício 2
-- Esperado: todas as linhas devem apresentar status = 'OK'.
-- Estas consultas não alteram dados.

WITH checks AS (

    SELECT
        '01_zonas_total' AS check_name,
        CASE WHEN COUNT(*) >= 7 THEN 'OK' ELSE 'FAIL' END AS status,
        COUNT(*)::TEXT AS observed,
        '>= 7 zonas' AS expected
    FROM zona

    UNION ALL

    SELECT
        '02_precos_zonas_entre_5_e_30',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 zonas fora de [5,30]'
    FROM zona
    WHERE preco < 5 OR preco > 30

    UNION ALL

    SELECT
        '03_zonas_so_categoria',
        CASE WHEN COUNT(*) >= 3 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '>= 3 zonas com categoria e continente NULL'
    FROM zona
    WHERE categoria IS NOT NULL
      AND continente IS NULL

    UNION ALL

    SELECT
        '04_zonas_so_continente',
        CASE WHEN COUNT(*) >= 2 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '>= 2 zonas com continente e categoria NULL'
    FROM zona
    WHERE categoria IS NULL
      AND continente IS NOT NULL

    UNION ALL

    SELECT
        '05_zonas_categoria_e_continente',
        CASE WHEN COUNT(*) >= 2 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '>= 2 zonas com categoria e continente'
    FROM zona
    WHERE categoria IS NOT NULL
      AND continente IS NOT NULL

    UNION ALL

    SELECT
        '06_especialidade_africa_sem_zona_africa_isolada',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 zonas com continente África e categoria NULL'
    FROM zona
    WHERE continente = 'África'
      AND categoria IS NULL

    UNION ALL

    SELECT
        '07_recintos_por_zona_entre_10_e_30',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 zonas com menos de 10 ou mais de 30 recintos'
    FROM (
        SELECT z.id_zona, COUNT(r.id_recinto) AS n_recintos
        FROM zona z
        LEFT JOIN recinto r
          ON r.id_zona = z.id_zona
        GROUP BY z.id_zona
        HAVING COUNT(r.id_recinto) < 10
            OR COUNT(r.id_recinto) > 30
    ) q

    UNION ALL

    SELECT
        '08_especies_total',
        CASE WHEN COUNT(*) >= 200 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '>= 200 espécies'
    FROM especie

    UNION ALL

    SELECT
        '09_especies_cobrem_todas_categorias',
        CASE WHEN COUNT(DISTINCT categoria) = 6 THEN 'OK' ELSE 'FAIL' END,
        COUNT(DISTINCT categoria)::TEXT,
        '6 categorias'
    FROM especie

    UNION ALL

    SELECT
        '10_especies_cobrem_todos_continentes',
        CASE WHEN COUNT(DISTINCT continente) = 5 THEN 'OK' ELSE 'FAIL' END,
        COUNT(DISTINCT continente)::TEXT,
        '5 continentes'
    FROM especie

    UNION ALL

    SELECT
        '11_animais_por_especie_min_max',
        CASE WHEN MIN(n_animais) >= 1 AND MAX(n_animais) <= 12 THEN 'OK' ELSE 'FAIL' END,
        'min=' || MIN(n_animais) || ', max=' || MAX(n_animais),
        '1 <= animais por espécie <= 12'
    FROM (
        SELECT nome_cientifico, COUNT(*) AS n_animais
        FROM animal
        GROUP BY nome_cientifico
    ) q

    UNION ALL

    SELECT
        '12_media_animais_por_especie',
        CASE WHEN AVG(n_animais) BETWEEN 2 AND 3 THEN 'OK' ELSE 'FAIL' END,
        ROUND(AVG(n_animais)::NUMERIC, 3)::TEXT,
        'média entre 2 e 3'
    FROM (
        SELECT nome_cientifico, COUNT(*) AS n_animais
        FROM animal
        GROUP BY nome_cientifico
    ) q

    UNION ALL

    SELECT
        '13_animais_sozinhos_so_em_especies_ate_3_animais',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 animais sozinhos pertencentes a espécies com mais de 3 animais'
    FROM (
        SELECT
            a.id_animal,
            a.nome_cientifico,
            COUNT(*) OVER (PARTITION BY a.id_recinto) AS animais_no_recinto,
            COUNT(*) OVER (PARTITION BY a.nome_cientifico) AS animais_da_especie
        FROM animal a
    ) q
    WHERE animais_no_recinto = 1
      AND animais_da_especie > 3

    UNION ALL

    SELECT
        '14_existem_recintos_com_um_animal',
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '> 0 recintos com apenas 1 animal'
    FROM (
        SELECT id_recinto
        FROM animal
        GROUP BY id_recinto
        HAVING COUNT(*) = 1
    ) q

    UNION ALL

    SELECT
        '15_existem_recintos_com_varios_animais_uma_especie',
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '> 0 recintos com vários animais de uma só espécie'
    FROM (
        SELECT id_recinto
        FROM animal
        GROUP BY id_recinto
        HAVING COUNT(*) > 1
           AND COUNT(DISTINCT nome_cientifico) = 1
    ) q

    UNION ALL

    SELECT
        '16_existem_recintos_com_varias_especies',
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '> 0 recintos com várias espécies'
    FROM (
        SELECT id_recinto
        FROM animal
        GROUP BY id_recinto
        HAVING COUNT(DISTINCT nome_cientifico) > 1
    ) q

    UNION ALL

    SELECT
        '17_ri2_compatibilidade_animal_zona',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 animais em zonas incompatíveis'
    FROM animal a
    JOIN especie e
      ON e.nome_cientifico = a.nome_cientifico
    JOIN recinto r
      ON r.id_recinto = a.id_recinto
    JOIN zona z
      ON z.id_zona = r.id_zona
    WHERE (z.categoria IS NOT NULL AND z.categoria <> e.categoria)
       OR (z.continente IS NOT NULL AND z.continente <> e.continente)

    UNION ALL

    SELECT
        '18_ri3_especie_numa_so_zona',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 espécies distribuídas por mais de uma zona'
    FROM (
        SELECT a.nome_cientifico
        FROM animal a
        JOIN recinto r
          ON r.id_recinto = a.id_recinto
        GROUP BY a.nome_cientifico
        HAVING COUNT(DISTINCT r.id_zona) > 1
    ) q

    UNION ALL

    SELECT
        '19_intervalo_datas_vendas',
        CASE
            WHEN MIN(data_hora::DATE) = DATE '2026-01-01'
             AND MAX(data_hora::DATE) = DATE '2026-06-11'
            THEN 'OK' ELSE 'FAIL'
        END,
        MIN(data_hora::DATE)::TEXT || ' a ' || MAX(data_hora::DATE)::TEXT,
        '2026-01-01 a 2026-06-11'
    FROM venda

    UNION ALL

    SELECT
        '20_todos_os_dias_tem_vendas',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 dias sem vendas no intervalo'
    FROM (
        SELECT d::DATE AS data
        FROM generate_series(DATE '2026-01-01', DATE '2026-06-11', INTERVAL '1 day') AS gs(d)
        EXCEPT
        SELECT DISTINCT data_hora::DATE
        FROM venda
    ) q

    UNION ALL

    SELECT
        '21_bilhetes_minimos_por_tipo_de_dia',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 dias abaixo dos mínimos: 1000 úteis, 4000 fim de semana'
    FROM (
        SELECT
            v.data_hora::DATE AS data,
            COUNT(b.bid) AS n_bilhetes
        FROM venda v
        JOIN bilhete b
          ON b.no_venda = v.no_venda
        GROUP BY v.data_hora::DATE
        HAVING
            (
                EXTRACT(ISODOW FROM v.data_hora::DATE) IN (6, 7)
                AND COUNT(b.bid) < 4000
            )
            OR
            (
                EXTRACT(ISODOW FROM v.data_hora::DATE) NOT IN (6, 7)
                AND COUNT(b.bid) < 1000
            )
    ) q

    UNION ALL

    SELECT
        '22_descontos_cerca_de_metade_por_dia',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 dias fora do intervalo [49%,51%] com desconto 0.50'
    FROM (
        SELECT
            v.data_hora::DATE AS data,
            AVG(CASE WHEN b.desconto = 0.50 THEN 1.0 ELSE 0.0 END) AS frac_desconto
        FROM venda v
        JOIN bilhete b
          ON b.no_venda = v.no_venda
        GROUP BY v.data_hora::DATE
        HAVING AVG(CASE WHEN b.desconto = 0.50 THEN 1.0 ELSE 0.0 END) NOT BETWEEN 0.49 AND 0.51
    ) q

    UNION ALL

    SELECT
        '23_acesso_total_minimo_2_porcento_por_dia',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 dias com menos de 2% bilhetes de acesso total'
    FROM (
        WITH n_zonas AS (
            SELECT COUNT(*) AS total_zonas FROM zona
        ),
        bilhetes_dia AS (
            SELECT
                v.data_hora::DATE AS data,
                b.bid,
                COUNT(a.id_zona) AS zonas_bilhete
            FROM venda v
            JOIN bilhete b
              ON b.no_venda = v.no_venda
            JOIN acesso a
              ON a.bid = b.bid
            GROUP BY v.data_hora::DATE, b.bid
        )
        SELECT bd.data
        FROM bilhetes_dia bd
        CROSS JOIN n_zonas nz
        GROUP BY bd.data
        HAVING AVG(CASE WHEN bd.zonas_bilhete = nz.total_zonas THEN 1.0 ELSE 0.0 END) < 0.02
    ) q

    UNION ALL

    SELECT
        '24_todas_zonas_em_10_bilhetes_por_dia',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 pares dia/zona com menos de 10 bilhetes'
    FROM (
        WITH dias AS (
            SELECT d::DATE AS data
            FROM generate_series(DATE '2026-01-01', DATE '2026-06-11', INTERVAL '1 day') AS gs(d)
        )
        SELECT d.data, z.id_zona
        FROM dias d
        CROSS JOIN zona z
        LEFT JOIN venda v
          ON v.data_hora::DATE = d.data
        LEFT JOIN bilhete b
          ON b.no_venda = v.no_venda
        LEFT JOIN acesso a
          ON a.bid = b.bid
         AND a.id_zona = z.id_zona
        GROUP BY d.data, z.id_zona
        HAVING COUNT(a.bid) < 10
    ) q

    UNION ALL

    SELECT
        '25_cada_bilhete_tem_pelo_menos_3_zonas',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 bilhetes com menos de 3 zonas'
    FROM (
        SELECT b.bid, COUNT(a.id_zona) AS n_zonas
        FROM bilhete b
        LEFT JOIN acesso a
          ON a.bid = b.bid
        GROUP BY b.bid
        HAVING COUNT(a.id_zona) < 3
    ) q

    UNION ALL

    SELECT
        '26_cada_zona_em_25_porcento_bilhetes_por_dia',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 pares dia/zona abaixo de 25%'
    FROM (
        WITH total_dia AS (
            SELECT v.data_hora::DATE AS data, COUNT(b.bid) AS total_bilhetes
            FROM venda v
            JOIN bilhete b
              ON b.no_venda = v.no_venda
            GROUP BY v.data_hora::DATE
        ),
        zona_dia AS (
            SELECT
                v.data_hora::DATE AS data,
                a.id_zona,
                COUNT(DISTINCT b.bid) AS bilhetes_zona
            FROM venda v
            JOIN bilhete b
              ON b.no_venda = v.no_venda
            JOIN acesso a
              ON a.bid = b.bid
            GROUP BY v.data_hora::DATE, a.id_zona
        )
        SELECT zd.data, zd.id_zona
        FROM zona_dia zd
        JOIN total_dia td
          ON td.data = zd.data
        WHERE zd.bilhetes_zona < 0.25 * td.total_bilhetes
    ) q

    UNION ALL

    SELECT
        '27_todas_combinacoes_3_ou_mais_zonas_existentes',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 combinações esperadas em falta'
    FROM (
        WITH z AS (
            SELECT id_zona, ROW_NUMBER() OVER (ORDER BY id_zona) - 1 AS idx
            FROM zona
        ),
        n AS (
            SELECT COUNT(*)::INTEGER AS n_zonas FROM z
        ),
        masks AS (
            SELECT generate_series(1, (1 << n_zonas) - 1) AS mask
            FROM n
        ),
        expected AS (
            SELECT STRING_AGG(z.id_zona::TEXT, ',' ORDER BY z.id_zona) AS combo
            FROM masks m
            JOIN z
              ON (m.mask & (1 << z.idx)) <> 0
            GROUP BY m.mask
            HAVING COUNT(*) >= 3
        ),
        observed AS (
            SELECT STRING_AGG(a.id_zona::TEXT, ',' ORDER BY a.id_zona) AS combo
            FROM acesso a
            GROUP BY a.bid
            HAVING COUNT(*) >= 3
        )
        SELECT e.combo
        FROM expected e
        WHERE NOT EXISTS (
            SELECT 1
            FROM observed o
            WHERE o.combo = e.combo
        )
    ) q

    UNION ALL

    SELECT
        '28_bilhetes_votou_true_minimo_75_porcento',
        CASE WHEN AVG(CASE WHEN votou THEN 1.0 ELSE 0.0 END) >= 0.75 THEN 'OK' ELSE 'FAIL' END,
        ROUND(AVG(CASE WHEN votou THEN 1.0 ELSE 0.0 END)::NUMERIC, 4)::TEXT,
        '>= 0.75'
    FROM bilhete

    UNION ALL

    SELECT
        '29_soma_votos_recintos_igual_bilhetes_votou_true',
        CASE
            WHEN (SELECT COALESCE(SUM(votos), 0) FROM recinto)
               = (SELECT COUNT(*) FROM bilhete WHERE votou)
            THEN 'OK' ELSE 'FAIL'
        END,
        'votos=' || (SELECT COALESCE(SUM(votos), 0) FROM recinto)
            || ', votou_true=' || (SELECT COUNT(*) FROM bilhete WHERE votou),
        'soma(votos) = count(bilhetes votou TRUE)'

    UNION ALL

    SELECT
        '30_votos_zona_nao_excedem_bilhetes_votantes_com_acesso',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 zonas com votos > bilhetes votantes com acesso'
    FROM (
        SELECT
            z.id_zona,
            COALESCE(SUM(r.votos), 0) AS votos_zona,
            COUNT(DISTINCT b.bid) AS bilhetes_votantes_com_acesso
        FROM zona z
        LEFT JOIN recinto r
          ON r.id_zona = z.id_zona
        LEFT JOIN acesso a
          ON a.id_zona = z.id_zona
        LEFT JOIN bilhete b
          ON b.bid = a.bid
         AND b.votou
        GROUP BY z.id_zona
        HAVING COALESCE(SUM(r.votos), 0) > COUNT(DISTINCT b.bid)
    ) q

    UNION ALL

    SELECT
        '31_cada_recinto_minimo_0_1_porcento_votos',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 recintos abaixo de 0.1% dos votos totais'
    FROM (
        WITH total AS (
            SELECT SUM(votos)::NUMERIC AS total_votos
            FROM recinto
        )
        SELECT r.id_recinto
        FROM recinto r
        CROSS JOIN total t
        WHERE r.votos < CEIL(0.001 * t.total_votos)
    ) q

    UNION ALL

    SELECT
        '32_ri4_vendas_com_bilhete_e_acesso',
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '0 vendas sem bilhete com pelo menos um acesso'
    FROM venda v
    WHERE NOT EXISTS (
        SELECT 1
        FROM bilhete b
        JOIN acesso a
          ON a.bid = b.bid
        WHERE b.no_venda = v.no_venda
    )

    UNION ALL

    SELECT
        '33_edge_existencia_bilhetes_com_exatamente_3_zonas',
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '> 0 bilhetes com exatamente 3 zonas'
    FROM (
        SELECT bid
        FROM acesso
        GROUP BY bid
        HAVING COUNT(*) = 3
    ) q

    UNION ALL

    SELECT
        '34_edge_existencia_bilhetes_com_acesso_total',
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'FAIL' END,
        COUNT(*)::TEXT,
        '> 0 bilhetes com acesso a todas as zonas'
    FROM (
        SELECT a.bid
        FROM acesso a
        GROUP BY a.bid
        HAVING COUNT(*) = (SELECT COUNT(*) FROM zona)
    ) q
)
SELECT *
FROM checks
ORDER BY check_name;
