%%sql zoo

CREATE OR REPLACE FUNCTION ri_2_verifica_compatibilidade_zona()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM animal a
        JOIN especie e
          ON e.nome_cientifico = a.nome_cientifico
        JOIN recinto r
          ON r.id_recinto = a.id_recinto
        JOIN zona z
          ON z.id_zona = r.id_zona
        WHERE
            (
                z.categoria IS NOT NULL
                AND z.categoria <> e.categoria
            )
            OR
            (
                z.continente IS NOT NULL
                AND z.continente <> e.continente
            )
    ) THEN
        RAISE EXCEPTION 'RI-2 violada: existe animal alojado numa zona incompatível com a sua espécie';
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

%%sql zoo 
    
    --Triggers
    
--alterações nos animais    
DROP TRIGGER IF EXISTS ri_2_animal ON animal;

CREATE CONSTRAINT TRIGGER ri_2_animal
AFTER INSERT OR UPDATE OF nome_cientifico, id_recinto ON animal
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION ri_2_verifica_compatibilidade_zona();

--alterações nos recintos
DROP TRIGGER IF EXISTS ri_2_recinto ON recinto;

CREATE CONSTRAINT TRIGGER ri_2_recinto
AFTER UPDATE OF id_zona ON recinto
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION ri_2_verifica_compatibilidade_zona();

--alterações nas zonas
DROP TRIGGER IF EXISTS ri_2_zona ON zona;

CREATE CONSTRAINT TRIGGER ri_2_zona
AFTER UPDATE OF categoria, continente ON zona
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION ri_2_verifica_compatibilidade_zona();

--alterações nas especies
DROP TRIGGER IF EXISTS ri_2_especie ON especie;

CREATE CONSTRAINT TRIGGER ri_2_especie
AFTER UPDATE OF categoria, continente ON especie
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION ri_2_verifica_compatibilidade_zona();