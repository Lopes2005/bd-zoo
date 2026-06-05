%%sql zoo

--Criação do índice diretamente associado à RI-4
CREATE INDEX IF NOT EXISTS idx_bilhete_no_venda ON bilhete(no_venda);

-- FUNÇÃO DE VERIFICAÇÃO DA RI-4 
CREATE OR REPLACE FUNCTION ri_4_verifica_venda () RETURNS TRIGGER AS $$
DECLARE
    venda_id INTEGER;
BEGIN
    IF TG_TABLE_NAME = 'venda' THEN
        IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
        venda_id := NEW.no_venda;
    ELSIF TG_TABLE_NAME = 'bilhete' THEN
        IF TG_OP = 'DELETE' THEN venda_id := OLD.no_venda; ELSE venda_id := NEW.no_venda; END IF;
    ELSIF TG_TABLE_NAME = 'acesso' THEN
        IF TG_OP = 'DELETE' THEN 
            SELECT no_venda INTO venda_id FROM bilhete WHERE bid = OLD.bid;
        ELSE 
            SELECT no_venda INTO venda_id FROM bilhete WHERE bid = NEW.bid;
        END IF;
    END IF;

    IF venda_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1
            FROM bilhete b
            JOIN acesso a ON a.bid = b.bid
            WHERE b.no_venda = venda_id
        ) THEN
            RAISE EXCEPTION 'RI-4 violada: a venda % não possui nenhum bilhete com acesso a pelo menos uma zona', venda_id;
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$ LANGUAGE plpgsql;

-- FUNÇÃO DE LOCK CONCORRENTE 
CREATE OR REPLACE FUNCTION ri_4_lock_venda () RETURNS TRIGGER AS $$
DECLARE
    venda_antiga INTEGER;
    venda_nova INTEGER;
    venda_a_bloquear INTEGER;
BEGIN
    IF TG_TABLE_NAME = 'bilhete' THEN
        IF TG_OP IN ('UPDATE', 'DELETE') THEN venda_antiga := OLD.no_venda; END IF;
        IF TG_OP IN ('INSERT', 'UPDATE') THEN venda_nova := NEW.no_venda; END IF;
    ELSIF TG_TABLE_NAME = 'acesso' THEN
        IF TG_OP IN ('UPDATE', 'DELETE') THEN
            SELECT b.no_venda INTO venda_antiga FROM bilhete b WHERE b.bid = OLD.bid;
        END IF;
        IF TG_OP IN ('INSERT', 'UPDATE') THEN
            SELECT b.no_venda INTO venda_nova FROM bilhete b WHERE b.bid = NEW.bid;
        END IF;
    END IF;

    FOR venda_a_bloquear IN
        SELECT DISTINCT x
        FROM (VALUES (venda_antiga), (venda_nova)) AS vendas(x)
        WHERE x IS NOT NULL
        ORDER BY x
    LOOP
        PERFORM 1 FROM venda WHERE no_venda = venda_a_bloquear FOR UPDATE;
    END LOOP;

    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$ LANGUAGE plpgsql;

-- TRIGGERS DE LOCK  - *Garante a segurança contra concorrência*
DROP TRIGGER IF EXISTS ri_4_lock_bilhete ON bilhete;
CREATE TRIGGER ri_4_lock_bilhete 
BEFORE INSERT OR UPDATE OR DELETE ON bilhete 
FOR EACH ROW EXECUTE FUNCTION ri_4_lock_venda ();

DROP TRIGGER IF EXISTS ri_4_lock_acesso ON acesso;
CREATE TRIGGER ri_4_lock_acesso 
BEFORE INSERT OR UPDATE OR DELETE ON acesso 
FOR EACH ROW EXECUTE FUNCTION ri_4_lock_venda ();

-- TRIGGERS DE RESTRIÇÃO OTIMIZADOS (AFTER DEFERRED)

-- Na venda, validamos após INSERIR ou ALTERAR
DROP TRIGGER IF EXISTS ri_4_venda ON venda;
CREATE CONSTRAINT TRIGGER ri_4_venda
AFTER INSERT OR UPDATE ON venda 
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION ri_4_verifica_venda ();

-- No bilhete, REMOVIDO o AFTER INSERT. Só valida em UPDATE ou DELETE.
DROP TRIGGER IF EXISTS ri_4_bilhete ON bilhete;
CREATE CONSTRAINT TRIGGER ri_4_bilhete
AFTER UPDATE OR DELETE ON bilhete 
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION ri_4_verifica_venda ();

-- No acesso, REMOVIDO o AFTER INSERT. Só valida em UPDATE ou DELETE.
DROP TRIGGER IF EXISTS ri_4_acesso ON acesso;
CREATE CONSTRAINT TRIGGER ri_4_acesso
AFTER UPDATE OR DELETE ON acesso 
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION ri_4_verifica_venda ();