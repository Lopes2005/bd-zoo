-- Exercício 2.1 — Zonas
-- Estratégia escolhida:
--   especialidade do zoo = continente 'África'.
--   Por isso existem várias zonas com continente='África' e categorias diferentes,
--   mas NÃO existe nenhuma zona com continente='África' e categoria NULL.

-- Este TRUNCATE torna o preenchimento reexecutável durante testes.
-- Deve ser executado depois da criação do esquema e das RIs.
TRUNCATE TABLE acesso, bilhete, venda, animal, especie, recinto, zona
RESTART IDENTITY CASCADE;

INSERT INTO zona (categoria, continente, preco) VALUES
    -- zonas da especialidade: partilham o continente África
    ('Aves',       'África', 18.00),
    ('Carnívoros', 'África', 25.00),
    ('Herbívoros', 'África', 20.00),

    -- zonas exclusivamente por categoria
    ('Primatas',            NULL, 22.00),
    ('Repteis',             NULL, 16.00),
    ('Mamíferos Marinhos',  NULL, 30.00),

    -- zonas exclusivamente por continente, sem usar África
    (NULL, 'Europa',    12.00),
    (NULL, 'Asia',      14.00),
    (NULL, 'América',   15.00),
    (NULL, 'Austrália', 17.00);
