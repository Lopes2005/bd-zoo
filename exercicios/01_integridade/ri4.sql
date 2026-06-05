%%sql zoo

-- RI-4
-- Regra corrigida segundo a clarificação do professor:
--   1) cada venda tem de incluir pelo menos um bilhete;
--   2) cada bilhete incluído na venda tem de ter acesso a pelo menos uma zona.
--
-- Implementação:
--   - constraint triggers DEFERRABLE INITIALLY DEFERRED, para permitir inserir
--     venda -> bilhete -> acesso dentro da mesma transação;
--   - índice em bilhete(no_venda), essencial para evitar SEQ_SCAN repetido
--     durante o carregamento massivo de dados;
--   - a tabela acesso já tem PRIMARY KEY (bid, id_zona), que indexa bid.

CREATE INDEX IF NOT EXISTS idx_bilhete_no_venda ON bilhete(no_venda);

-- Função auxiliar: verifica a RI-4 para uma venda concreta.
-- Está separada da trigger function para tornar a regra explícita e reutilizável.
CREATE OR REPLACE FUNCTION ri_4_verifica_venda_id(p_no_venda INTEGER)
RETURNS VOID AS $$
DECLARE
    bilhete_sem_acesso INTEGER;
BEGIN
    -- Se a venda já não existir, não há nada a validar.
    -- Isto evita falsos erros durante remoções/cascatas.
    IF p_no_venda IS NULL OR NOT EXISTS (
        SELECT 1
        FROM venda v
        WHERE v.no_venda = p_no_venda
    ) THEN
        RETURN;
    END IF;

    -- Parte 1 da RI-4: a venda tem de incluir pelo menos um bilhete.
    IF NOT EXISTS (
        SELECT 1
        FROM bilhete b
        WHERE b.no_venda = p_no_venda
    ) THEN
        RAISE EXCEPTION
            'RI-4 violada: a venda % não inclui nenhum bilhete',
            p_no_venda;
    END IF;

    -- Parte 2 da RI-4: cada bilhete da venda tem de ter pelo menos um acesso.
    SELECT b.bid
    INTO bilhete_sem_acesso
    FROM bilhete b
    WHERE b.no_venda = p_no_venda
      AND NOT EXISTS (
          SELECT 1
          FROM acesso a
          WHERE a.bid = b.bid
      )
    LIMIT 1;

    IF bilhete_sem_acesso IS NOT NULL THEN
        RAISE EXCEPTION
            'RI-4 violada: o bilhete % da venda % não tem acesso a nenhuma zona',
            bilhete_sem_acesso,
            p_no_venda;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger function de verificação.
-- Verifica todas as vendas afetadas pela operação:
--   venda: NEW/OLD.no_venda;
--   bilhete: OLD.no_venda e/ou NEW.no_venda;
--   acesso: venda associada ao OLD.bid e/ou NEW.bid.
CREATE OR REPLACE FUNCTION ri_4_verifica_venda()
RETURNS TRIGGER AS $$
DECLARE
    venda_antiga INTEGER;
    venda_nova INTEGER;
    venda_a_verificar INTEGER;
BEGIN
    IF TG_TABLE_NAME = 'venda' THEN
        IF TG_OP IN ('UPDATE', 'DELETE') THEN
            venda_antiga := OLD.no_venda;
        END IF;
        IF TG_OP IN ('INSERT', 'UPDATE') THEN
            venda_nova := NEW.no_venda;
        END IF;

    ELSIF TG_TABLE_NAME = 'bilhete' THEN
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

    FOR venda_a_verificar IN
        SELECT DISTINCT x
        FROM (VALUES (venda_antiga), (venda_nova)) AS vendas(x)
        WHERE x IS NOT NULL
        ORDER BY x
    LOOP
        PERFORM ri_4_verifica_venda_id(venda_a_verificar);
    END LOOP;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger function de lock.
-- Serializa alterações concorrentes que afetem a mesma venda.
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

    -- Bloqueia sempre por ordem crescente para reduzir risco de deadlocks.
    FOR venda_a_bloquear IN
        SELECT DISTINCT x
        FROM (VALUES (venda_antiga), (venda_nova)) AS vendas(x)
        WHERE x IS NOT NULL
        ORDER BY x
    LOOP
        PERFORM 1
        FROM venda v
        WHERE v.no_venda = venda_a_bloquear
        FOR UPDATE;
    END LOOP;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Remover triggers anteriores para tornar o ficheiro reexecutável.
DROP TRIGGER IF EXISTS ri_4_lock_bilhete ON bilhete;
DROP TRIGGER IF EXISTS ri_4_lock_acesso ON acesso;
DROP TRIGGER IF EXISTS ri_4_venda ON venda;
DROP TRIGGER IF EXISTS ri_4_bilhete ON bilhete;
DROP TRIGGER IF EXISTS ri_4_acesso ON acesso;

-- Locks concorrentes.
CREATE TRIGGER ri_4_lock_bilhete
BEFORE INSERT OR UPDATE OR DELETE ON bilhete
FOR EACH ROW
EXECUTE FUNCTION ri_4_lock_venda();

CREATE TRIGGER ri_4_lock_acesso
BEFORE INSERT OR UPDATE OR DELETE ON acesso
FOR EACH ROW
EXECUTE FUNCTION ri_4_lock_venda();

-- Verificação diferida da venda.
-- A venda recém-criada pode estar temporariamente sem bilhetes dentro da transação,
-- desde que no COMMIT já tenha pelo menos um bilhete e que todos os bilhetes tenham acesso.
CREATE CONSTRAINT TRIGGER ri_4_venda
AFTER INSERT OR UPDATE ON venda
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION ri_4_verifica_venda();

-- IMPORTANTE: inclui INSERT em bilhete.
-- Sem isto, seria possível adicionar um bilhete sem acesso a uma venda já válida.
CREATE CONSTRAINT TRIGGER ri_4_bilhete
AFTER INSERT OR UPDATE OR DELETE ON bilhete
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION ri_4_verifica_venda();

-- Em acesso, INSERT não pode violar a RI-4; só UPDATE/DELETE podem retirar o último
-- acesso de um bilhete ou mover acessos entre bilhetes/vendas.
CREATE CONSTRAINT TRIGGER ri_4_acesso
AFTER UPDATE OR DELETE ON acesso
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION ri_4_verifica_venda();