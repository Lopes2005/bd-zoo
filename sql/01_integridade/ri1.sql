%%sql zoo


ALTER TABLE zona
DROP CONSTRAINT IF EXISTS ri_1_zona_categoria_ou_continente;

--CHECK, funciona porque só acedemos uma unica linha, neste caso de zona
ALTER TABLE zona
ADD CONSTRAINT ri_1_zona_categoria_ou_continente
CHECK (
    categoria IS NOT NULL
    OR continente IS NOT NULL
);
