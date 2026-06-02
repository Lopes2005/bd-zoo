%%sql zoo

CREATE OR REPLACE FUNCTION ri_3_verifica_especie_uma_zona()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM animal a
        JOIN recinto r
          ON r.id_recinto = a.id_recinto
        GROUP BY a.nome_cientifico
        HAVING COUNT(DISTINCT r.id_zona) > 1
    ) THEN
        RAISE EXCEPTION 'RI-3 violada: existem animais da mesma espécie em zonas diferentes';
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

%%sql zoo 
    
    --Triggers

-- cubre alterações nos animais
DROP TRIGGER IF EXISTS ri_3_animal ON animal;

CREATE CONSTRAINT TRIGGER ri_3_animal
AFTER INSERT OR UPDATE OF nome_cientifico, id_recinto ON animal
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION ri_3_verifica_especie_uma_zona();

-- cubre alterações nos recintos
DROP TRIGGER IF EXISTS ri_3_recinto ON recinto;

CREATE CONSTRAINT TRIGGER ri_3_recinto
AFTER UPDATE OF id_zona ON recinto
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION ri_3_verifica_especie_uma_zona();