%%sql zoo

CREATE OR REPLACE FUNCTION ri_4_verifica_venda()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM venda v
        WHERE NOT EXISTS (
            SELECT 1
            FROM bilhete b
            JOIN acesso a
              ON a.bid = b.bid
            WHERE b.no_venda = v.no_venda
        )
    ) THEN
        RAISE EXCEPTION
        'RI-4 violada: existe venda sem bilhete com acesso a pelo menos uma zona';
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;



%%sql zoo

--Função de lock especializada para diferentes tipos de alterações
    -- A RI-4 é verificada no fim da transação, mas alterações concorrentes
    -- à mesma venda podem causar anomalias. Por isso bloqueamos a linha
    -- correspondente em venda com SELECT ... FOR UPDATE sempre que são
    -- alterados bilhetes ou acessos dessa venda.
    
CREATE OR REPLACE FUNCTION ri_4_lock_venda()
RETURNS TRIGGER AS $$
DECLARE
    venda_antiga INTEGER;
    venda_nova INTEGER;
    venda_a_bloquear INTEGER;
BEGIN
    IF TG_TABLE_NAME = 'bilhete' THEN

        IF TG_OP IN ('UPDATE', 'DELETE') THEN
            venda_antiga := OLD.no_venda;
        END IF;

        IF TG_OP IN ('INSERT', 'UPDATE') THEN
            venda_nova := NEW.no_venda;
        END IF;

    ELSIF TG_TABLE_NAME = 'acesso' THEN

        IF TG_OP IN ('UPDATE', 'DELETE') THEN
            SELECT b.no_venda
            INTO venda_antiga
            FROM bilhete b
            WHERE b.bid = OLD.bid;
        END IF;

        IF TG_OP IN ('INSERT', 'UPDATE') THEN
            SELECT b.no_venda
            INTO venda_nova
            FROM bilhete b
            WHERE b.bid = NEW.bid;
        END IF;

    END IF;

    FOR venda_a_bloquear IN
        SELECT DISTINCT x
        FROM (
            VALUES (venda_antiga), (venda_nova)
        ) AS vendas(x)
        WHERE x IS NOT NULL
        ORDER BY x
    LOOP
        PERFORM 1
        FROM venda
        WHERE no_venda = venda_a_bloquear
        FOR UPDATE;
    END LOOP;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;



%%sql zoo

-- Triggers BEFORE, para bloquear a venda antes de alterar bilhetes ou acessos
DROP TRIGGER IF EXISTS ri_4_lock_bilhete ON bilhete;

CREATE TRIGGER ri_4_lock_bilhete
BEFORE INSERT OR UPDATE OR DELETE ON bilhete
FOR EACH ROW
EXECUTE FUNCTION ri_4_lock_venda();


DROP TRIGGER IF EXISTS ri_4_lock_acesso ON acesso;

CREATE TRIGGER ri_4_lock_acesso
BEFORE INSERT OR UPDATE OR DELETE ON acesso
FOR EACH ROW
EXECUTE FUNCTION ri_4_lock_venda();



%%sql zoo

--Triggers que efectivamente impõem a RI-4 no fim da transação
DROP TRIGGER IF EXISTS ri_4_venda ON venda;

CREATE CONSTRAINT TRIGGER ri_4_venda
AFTER INSERT OR UPDATE ON venda
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION ri_4_verifica_venda();


DROP TRIGGER IF EXISTS ri_4_bilhete ON bilhete;

CREATE CONSTRAINT TRIGGER ri_4_bilhete
AFTER INSERT OR UPDATE OR DELETE ON bilhete
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION ri_4_verifica_venda();


DROP TRIGGER IF EXISTS ri_4_acesso ON acesso;

CREATE CONSTRAINT TRIGGER ri_4_acesso
AFTER INSERT OR UPDATE OR DELETE ON acesso
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION ri_4_verifica_venda();