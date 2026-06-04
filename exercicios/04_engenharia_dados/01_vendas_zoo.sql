%%sql zoo
CREATE MATERIALIZED VIEW vendas_zoo AS
SELECT 
    b.bid,
    a.id_zona,
    EXTRACT(MONTH FROM v.data_hora) AS mes,
    EXTRACT(DOW FROM v.data_hora) AS dia_da_semana,
    v.data_hora::DATE AS data,
    (z.preco * (1 - (b.desconto / 100)))::NUMERIC(6,2) AS receita
FROM 
    venda v
    JOIN bilhete b ON v.no_venda = b.no_venda
    JOIN acesso a ON b.bid = a.bid
    JOIN zona z ON a.id_zona = z.id_zona;