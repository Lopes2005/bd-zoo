
-- ============================================================
-- 01_zonas.sql
-- ============================================================

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


-- ============================================================
-- 02_recintos.sql
-- ============================================================

-- Exercício 2.2 — Recintos
-- Cada zona fica com 12 recintos.
-- Isto satisfaz o intervalo exigido: entre 10 e 30 recintos por zona.
-- Os votos são inicializados a 0 e atualizados após a criação dos bilhetes.

INSERT INTO recinto (id_zona, votos)
SELECT z.id_zona, 0
FROM zona z
CROSS JOIN generate_series(1, 12) AS g(n)
ORDER BY z.id_zona, g.n;


-- ============================================================
-- 03_especies.sql
-- ============================================================

-- Exercício 2.3 — Espécies
-- Lista com 216 espécies reais, cobrindo todas as categorias e todos os continentes.
-- Os nomes científicos respeitam o CHECK do esquema: 'Genus species'.

INSERT INTO especie (nome_cientifico, nome_comum, categoria, continente) VALUES
    ('Struthio camelus', 'avestruz-comum', 'Aves', 'África'),
    ('Sagittarius serpentarius', 'secretário', 'Aves', 'África'),
    ('Balaeniceps rex', 'bico-de-sapato', 'Aves', 'África'),
    ('Bubo lacteus', 'bufo-de-verreaux', 'Aves', 'África'),
    ('Bucorvus leadbeateri', 'calau-terrestre-do-sul', 'Aves', 'África'),
    ('Psittacus erithacus', 'papagaio-cinzento', 'Aves', 'África'),
    ('Agapornis roseicollis', 'inseparável-de-faces-rosadas', 'Aves', 'África'),
    ('Numida meleagris', 'galinha-da-guiné', 'Aves', 'África'),
    ('Ara macao', 'arara-vermelha', 'Aves', 'América'),
    ('Ramphastos sulfuratus', 'tucano-de-bico-arco-íris', 'Aves', 'América'),
    ('Vultur gryphus', 'condor-dos-andes', 'Aves', 'América'),
    ('Rhea americana', 'ema-comum', 'Aves', 'América'),
    ('Harpia harpyja', 'harpia', 'Aves', 'América'),
    ('Phoenicopterus ruber', 'flamingo-americano', 'Aves', 'América'),
    ('Spheniscus humboldti', 'pinguim-de-humboldt', 'Aves', 'América'),
    ('Pavo cristatus', 'pavão-indiano', 'Aves', 'Asia'),
    ('Grus antigone', 'grou-sarus', 'Aves', 'Asia'),
    ('Buceros bicornis', 'calau-grande', 'Aves', 'Asia'),
    ('Gracula religiosa', 'mainá-religiosa', 'Aves', 'Asia'),
    ('Lophura nycthemera', 'faisão-prateado', 'Aves', 'Asia'),
    ('Copsychus saularis', 'rouxinol-oriental', 'Aves', 'Asia'),
    ('Nipponia nippon', 'íbis-japonês', 'Aves', 'Asia'),
    ('Dromaius novaehollandiae', 'emu', 'Aves', 'Austrália'),
    ('Casuarius casuarius', 'casuar-do-sul', 'Aves', 'Austrália'),
    ('Melopsittacus undulatus', 'periquito-australiano', 'Aves', 'Austrália'),
    ('Eolophus roseicapilla', 'cacatua-galah', 'Aves', 'Austrália'),
    ('Menura novaehollandiae', 'ave-lira-soberba', 'Aves', 'Austrália'),
    ('Trichoglossus moluccanus', 'lóris-arco-íris', 'Aves', 'Austrália'),
    ('Ninox strenua', 'coruja-poderosa', 'Aves', 'Austrália'),
    ('Cygnus olor', 'cisne-mudo', 'Aves', 'Europa'),
    ('Corvus corax', 'corvo-comum', 'Aves', 'Europa'),
    ('Falco peregrinus', 'falcão-peregrino', 'Aves', 'Europa'),
    ('Bubo bubo', 'bufo-real', 'Aves', 'Europa'),
    ('Ciconia ciconia', 'cegonha-branca', 'Aves', 'Europa'),
    ('Erithacus rubecula', 'pisco-de-peito-ruivo', 'Aves', 'Europa'),
    ('Sturnus vulgaris', 'estorninho-comum', 'Aves', 'Europa'),
    ('Panthera leo', 'leão', 'Carnívoros', 'África'),
    ('Panthera pardus', 'leopardo-africano', 'Carnívoros', 'África'),
    ('Acinonyx jubatus', 'chita', 'Carnívoros', 'África'),
    ('Crocuta crocuta', 'hiena-malhada', 'Carnívoros', 'África'),
    ('Lycaon pictus', 'mabeco', 'Carnívoros', 'África'),
    ('Caracal caracal', 'caracal', 'Carnívoros', 'África'),
    ('Leptailurus serval', 'serval', 'Carnívoros', 'África'),
    ('Suricata suricatta', 'suricata', 'Carnívoros', 'África'),
    ('Panthera onca', 'jaguar', 'Carnívoros', 'América'),
    ('Puma concolor', 'puma', 'Carnívoros', 'América'),
    ('Tremarctos ornatus', 'urso-de-óculos', 'Carnívoros', 'América'),
    ('Nasua nasua', 'quati', 'Carnívoros', 'América'),
    ('Procyon lotor', 'guaxinim', 'Carnívoros', 'América'),
    ('Lontra canadensis', 'lontra-norte-americana', 'Carnívoros', 'América'),
    ('Chrysocyon brachyurus', 'lobo-guará', 'Carnívoros', 'América'),
    ('Panthera tigris', 'tigre', 'Carnívoros', 'Asia'),
    ('Panthera uncia', 'leopardo-das-neves', 'Carnívoros', 'Asia'),
    ('Ailurus fulgens', 'panda-vermelho', 'Carnívoros', 'Asia'),
    ('Helarctos malayanus', 'urso-malaio', 'Carnívoros', 'Asia'),
    ('Ursus thibetanus', 'urso-negro-asiático', 'Carnívoros', 'Asia'),
    ('Cuon alpinus', 'cão-selvagem-asiático', 'Carnívoros', 'Asia'),
    ('Prionailurus bengalensis', 'gato-leopardo', 'Carnívoros', 'Asia'),
    ('Canis dingo', 'dingo', 'Carnívoros', 'Austrália'),
    ('Sarcophilus harrisii', 'diabo-da-tasmânia', 'Carnívoros', 'Austrália'),
    ('Dasyurus maculatus', 'quoll-malhado', 'Carnívoros', 'Austrália'),
    ('Dasyurus viverrinus', 'quoll-oriental', 'Carnívoros', 'Austrália'),
    ('Dasyurus hallucatus', 'quoll-do-norte', 'Carnívoros', 'Austrália'),
    ('Antechinus flavipes', 'antequino-de-pés-amarelos', 'Carnívoros', 'Austrália'),
    ('Thylacinus cynocephalus', 'tilacino', 'Carnívoros', 'Austrália'),
    ('Canis lupus', 'lobo-cinzento', 'Carnívoros', 'Europa'),
    ('Vulpes vulpes', 'raposa-vermelha', 'Carnívoros', 'Europa'),
    ('Ursus arctos', 'urso-pardo', 'Carnívoros', 'Europa'),
    ('Lynx lynx', 'lince-euroasiático', 'Carnívoros', 'Europa'),
    ('Meles meles', 'texugo-europeu', 'Carnívoros', 'Europa'),
    ('Martes martes', 'marta-europeia', 'Carnívoros', 'Europa'),
    ('Mustela erminea', 'arminho', 'Carnívoros', 'Europa'),
    ('Loxodonta africana', 'elefante-africano', 'Herbívoros', 'África'),
    ('Giraffa camelopardalis', 'girafa', 'Herbívoros', 'África'),
    ('Hippopotamus amphibius', 'hipopótamo-comum', 'Herbívoros', 'África'),
    ('Diceros bicornis', 'rinoceronte-negro', 'Herbívoros', 'África'),
    ('Ceratotherium simum', 'rinoceronte-branco', 'Herbívoros', 'África'),
    ('Equus quagga', 'zebra-das-planícies', 'Herbívoros', 'África'),
    ('Syncerus caffer', 'búfalo-africano', 'Herbívoros', 'África'),
    ('Tragelaphus strepsiceros', 'cudo-maior', 'Herbívoros', 'África'),
    ('Tapirus terrestris', 'anta-sul-americana', 'Herbívoros', 'América'),
    ('Lama glama', 'lhama', 'Herbívoros', 'América'),
    ('Vicugna vicugna', 'vicunha', 'Herbívoros', 'América'),
    ('Hydrochoerus hydrochaeris', 'capivara', 'Herbívoros', 'América'),
    ('Odocoileus virginianus', 'veado-de-cauda-branca', 'Herbívoros', 'América'),
    ('Bison bison', 'bisão-americano', 'Herbívoros', 'América'),
    ('Mazama americana', 'veado-mateiro', 'Herbívoros', 'América'),
    ('Elephas maximus', 'elefante-asiático', 'Herbívoros', 'Asia'),
    ('Rhinoceros unicornis', 'rinoceronte-indiano', 'Herbívoros', 'Asia'),
    ('Camelus bactrianus', 'camelo-bactriano', 'Herbívoros', 'Asia'),
    ('Bubalus arnee', 'búfalo-selvagem-asiático', 'Herbívoros', 'Asia'),
    ('Bos gaurus', 'gaur', 'Herbívoros', 'Asia'),
    ('Axis axis', 'chital', 'Herbívoros', 'Asia'),
    ('Rusa unicolor', 'sambar', 'Herbívoros', 'Asia'),
    ('Macropus rufus', 'canguru-vermelho', 'Herbívoros', 'Austrália'),
    ('Phascolarctos cinereus', 'coala', 'Herbívoros', 'Austrália'),
    ('Vombatus ursinus', 'vombate-comum', 'Herbívoros', 'Austrália'),
    ('Notamacropus rufogriseus', 'wallaby-de-pescoço-vermelho', 'Herbívoros', 'Austrália'),
    ('Osphranter robustus', 'wallaroo-comum', 'Herbívoros', 'Austrália'),
    ('Lasiorhinus latifrons', 'vombate-de-nariz-peludo', 'Herbívoros', 'Austrália'),
    ('Petrogale penicillata', 'wallaby-das-rochas', 'Herbívoros', 'Austrália'),
    ('Bison bonasus', 'bisão-europeu', 'Herbívoros', 'Europa'),
    ('Capreolus capreolus', 'corço', 'Herbívoros', 'Europa'),
    ('Cervus elaphus', 'veado-vermelho', 'Herbívoros', 'Europa'),
    ('Dama dama', 'gamo', 'Herbívoros', 'Europa'),
    ('Rupicapra rupicapra', 'camurça', 'Herbívoros', 'Europa'),
    ('Ovis aries', 'carneiro-doméstico', 'Herbívoros', 'Europa'),
    ('Capra ibex', 'íbex-dos-alpes', 'Herbívoros', 'Europa'),
    ('Arctocephalus pusillus', 'lobo-marinho-do-cabo', 'Mamíferos Marinhos', 'África'),
    ('Monachus monachus', 'foca-monge-do-mediterrâneo', 'Mamíferos Marinhos', 'África'),
    ('Sousa plumbea', 'golfinho-corcunda-do-índico', 'Mamíferos Marinhos', 'África'),
    ('Delphinus capensis', 'golfinho-comum-de-bico-longo', 'Mamíferos Marinhos', 'África'),
    ('Megaptera novaeangliae', 'baleia-jubarte', 'Mamíferos Marinhos', 'África'),
    ('Eubalaena australis', 'baleia-franca-austral', 'Mamíferos Marinhos', 'África'),
    ('Lagenorhynchus obscurus', 'golfinho-de-peale', 'Mamíferos Marinhos', 'África'),
    ('Zalophus californianus', 'leão-marinho-da-califórnia', 'Mamíferos Marinhos', 'América'),
    ('Mirounga angustirostris', 'elefante-marinho-do-norte', 'Mamíferos Marinhos', 'América'),
    ('Enhydra lutris', 'lontra-marinha', 'Mamíferos Marinhos', 'América'),
    ('Trichechus manatus', 'manatim-das-antilhas', 'Mamíferos Marinhos', 'América'),
    ('Phocoena sinus', 'vaquita', 'Mamíferos Marinhos', 'América'),
    ('Eschrichtius robustus', 'baleia-cinzenta', 'Mamíferos Marinhos', 'América'),
    ('Tursiops truncatus', 'golfinho-roaz', 'Mamíferos Marinhos', 'América'),
    ('Orcinus orca', 'orca', 'Mamíferos Marinhos', 'América'),
    ('Neophocaena phocaenoides', 'toninha-sem-barbatana', 'Mamíferos Marinhos', 'Asia'),
    ('Dugong dugon', 'dugongo', 'Mamíferos Marinhos', 'Asia'),
    ('Lipotes vexillifer', 'baiji', 'Mamíferos Marinhos', 'Asia'),
    ('Platanista gangetica', 'golfinho-do-ganges', 'Mamíferos Marinhos', 'Asia'),
    ('Sousa chinensis', 'golfinho-corcunda-chinês', 'Mamíferos Marinhos', 'Asia'),
    ('Balaenoptera omurai', 'baleia-de-omura', 'Mamíferos Marinhos', 'Asia'),
    ('Pusa sibirica', 'foca-do-baikal', 'Mamíferos Marinhos', 'Asia'),
    ('Neophoca cinerea', 'leão-marinho-australiano', 'Mamíferos Marinhos', 'Austrália'),
    ('Arctocephalus forsteri', 'lobo-marinho-da-nova-zelândia', 'Mamíferos Marinhos', 'Austrália'),
    ('Tursiops aduncus', 'golfinho-roaz-do-índico', 'Mamíferos Marinhos', 'Austrália'),
    ('Balaenoptera musculus', 'baleia-azul', 'Mamíferos Marinhos', 'Austrália'),
    ('Hydrurga leptonyx', 'foca-leopardo', 'Mamíferos Marinhos', 'Austrália'),
    ('Lobodon carcinophaga', 'foca-caranguejeira', 'Mamíferos Marinhos', 'Austrália'),
    ('Leptonychotes weddellii', 'foca-de-weddell', 'Mamíferos Marinhos', 'Austrália'),
    ('Phocoena phocoena', 'toninha-comum', 'Mamíferos Marinhos', 'Europa'),
    ('Halichoerus grypus', 'foca-cinzenta', 'Mamíferos Marinhos', 'Europa'),
    ('Phoca vitulina', 'foca-comum', 'Mamíferos Marinhos', 'Europa'),
    ('Cystophora cristata', 'foca-de-capuz', 'Mamíferos Marinhos', 'Europa'),
    ('Pagophilus groenlandicus', 'foca-da-groenlândia', 'Mamíferos Marinhos', 'Europa'),
    ('Globicephala melas', 'baleia-piloto', 'Mamíferos Marinhos', 'Europa'),
    ('Delphinus delphis', 'golfinho-comum', 'Mamíferos Marinhos', 'Europa'),
    ('Gorilla gorilla', 'gorila-ocidental', 'Primatas', 'África'),
    ('Pan troglodytes', 'chimpanzé-comum', 'Primatas', 'África'),
    ('Pan paniscus', 'bonobo', 'Primatas', 'África'),
    ('Papio anubis', 'babuíno-anúbis', 'Primatas', 'África'),
    ('Mandrillus sphinx', 'mandril', 'Primatas', 'África'),
    ('Cercopithecus mitis', 'macaco-azul', 'Primatas', 'África'),
    ('Colobus guereza', 'colobo-guereza', 'Primatas', 'África'),
    ('Erythrocebus patas', 'macaco-patas', 'Primatas', 'África'),
    ('Chlorocebus pygerythrus', 'macaco-vervet', 'Primatas', 'África'),
    ('Galago senegalensis', 'gálago-do-senegal', 'Primatas', 'África'),
    ('Alouatta caraya', 'bugio-preto', 'Primatas', 'América'),
    ('Cebus capucinus', 'macaco-prego-de-cara-branca', 'Primatas', 'América'),
    ('Saimiri sciureus', 'macaco-de-cheiro', 'Primatas', 'América'),
    ('Ateles geoffroyi', 'macaco-aranha-de-geoffroy', 'Primatas', 'América'),
    ('Callithrix jacchus', 'sagui-comum', 'Primatas', 'América'),
    ('Leontopithecus rosalia', 'mico-leão-dourado', 'Primatas', 'América'),
    ('Aotus trivirgatus', 'macaco-da-noite', 'Primatas', 'América'),
    ('Pithecia pithecia', 'saki-de-cara-branca', 'Primatas', 'América'),
    ('Lagothrix lagotricha', 'macaco-barrigudo', 'Primatas', 'América'),
    ('Saguinus oedipus', 'sagui-cabeça-de-algodão', 'Primatas', 'América'),
    ('Pongo pygmaeus', 'orangotango-de-bornéu', 'Primatas', 'Asia'),
    ('Pongo abelii', 'orangotango-de-sumatra', 'Primatas', 'Asia'),
    ('Macaca mulatta', 'macaco-rhesus', 'Primatas', 'Asia'),
    ('Hylobates lar', 'gibão-de-mãos-brancas', 'Primatas', 'Asia'),
    ('Trachypithecus obscurus', 'langur-escuro', 'Primatas', 'Asia'),
    ('Nasalis larvatus', 'macaco-narigudo', 'Primatas', 'Asia'),
    ('Nycticebus coucang', 'lóris-lento', 'Primatas', 'Asia'),
    ('Symphalangus syndactylus', 'siamang', 'Primatas', 'Asia'),
    ('Hylobates agilis', 'gibão-ágil', 'Primatas', 'Asia'),
    ('Macaca fascicularis', 'macaco-cynomolgus', 'Primatas', 'Asia'),
    ('Macaca fuscata', 'macaco-japonês', 'Primatas', 'Asia'),
    ('Semnopithecus entellus', 'langur-cinzento', 'Primatas', 'Asia'),
    ('Presbytis melalophos', 'surili-de-crista', 'Primatas', 'Asia'),
    ('Tarsius tarsier', 'társio-espectral', 'Primatas', 'Asia'),
    ('Nomascus leucogenys', 'gibão-de-bochechas-brancas', 'Primatas', 'Asia'),
    ('Macaca sylvanus', 'macaco-de-gibraltar', 'Primatas', 'Europa'),
    ('Crocodylus niloticus', 'crocodilo-do-nilo', 'Repteis', 'África'),
    ('Python regius', 'pitão-real', 'Repteis', 'África'),
    ('Varanus niloticus', 'varano-do-nilo', 'Repteis', 'África'),
    ('Centrochelys sulcata', 'tartaruga-sulcata', 'Repteis', 'África'),
    ('Bitis arietans', 'víbora-sopradora', 'Repteis', 'África'),
    ('Dendroaspis polylepis', 'mamba-negra', 'Repteis', 'África'),
    ('Chamaeleo dilepis', 'camaleão-de-pescoço-largo', 'Repteis', 'África'),
    ('Naja haje', 'cobra-egípcia', 'Repteis', 'África'),
    ('Iguana iguana', 'iguana-verde', 'Repteis', 'América'),
    ('Caiman crocodilus', 'jacaré-tinga', 'Repteis', 'América'),
    ('Eunectes murinus', 'sucuri-verde', 'Repteis', 'América'),
    ('Chelonoidis carbonarius', 'jabuti-piranga', 'Repteis', 'América'),
    ('Crotalus durissus', 'cascavel-sul-americana', 'Repteis', 'América'),
    ('Boa constrictor', 'jiboia', 'Repteis', 'América'),
    ('Alligator mississippiensis', 'aligátor-americano', 'Repteis', 'América'),
    ('Python bivittatus', 'pitão-birmanesa', 'Repteis', 'Asia'),
    ('Gavialis gangeticus', 'gavial', 'Repteis', 'Asia'),
    ('Varanus komodoensis', 'dragão-de-komodo', 'Repteis', 'Asia'),
    ('Ophiophagus hannah', 'cobra-rei', 'Repteis', 'Asia'),
    ('Gekko gecko', 'gêco-tokay', 'Repteis', 'Asia'),
    ('Crocodylus porosus', 'crocodilo-de-água-salgada', 'Repteis', 'Asia'),
    ('Testudo horsfieldii', 'tartaruga-russa', 'Repteis', 'Asia'),
    ('Varanus giganteus', 'perentie', 'Repteis', 'Austrália'),
    ('Crocodylus johnstoni', 'crocodilo-de-johnston', 'Repteis', 'Austrália'),
    ('Pogona vitticeps', 'dragão-barbudo', 'Repteis', 'Austrália'),
    ('Morelia spilota', 'pitão-tapete', 'Repteis', 'Austrália'),
    ('Chelodina longicollis', 'tartaruga-de-pescoço-comprido', 'Repteis', 'Austrália'),
    ('Tiliqua scincoides', 'lagarto-de-língua-azul', 'Repteis', 'Austrália'),
    ('Oxyuranus scutellatus', 'taipan-costeiro', 'Repteis', 'Austrália'),
    ('Vipera berus', 'víbora-europeia', 'Repteis', 'Europa'),
    ('Testudo hermanni', 'tartaruga-de-hermann', 'Repteis', 'Europa'),
    ('Lacerta viridis', 'lagarto-verde-europeu', 'Repteis', 'Europa'),
    ('Natrix natrix', 'cobra-de-água', 'Repteis', 'Europa'),
    ('Zamenis longissimus', 'cobra-de-esculápio', 'Repteis', 'Europa'),
    ('Emys orbicularis', 'cágado-europeu', 'Repteis', 'Europa'),
    ('Podarcis muralis', 'lagartixa-dos-muros', 'Repteis', 'Europa');


-- ============================================================
-- 04_animais.sql
-- ============================================================

-- Exercício 2.4 — Animais
-- Estratégia:
--   1) cada espécie é colocada numa zona compatível, preferindo zona exacta
--      (categoria+continente), depois zona de categoria, depois zona de continente;
--   2) todos os animais da mesma espécie ficam numa única zona, satisfazendo RI-3;
--   3) cada espécie tem 1, 2 ou 3 animais, logo a média fica entre 2 e 3;
--   4) reserva-se o primeiro recinto de cada zona para uma espécie com 1 animal,
--      garantindo recintos com apenas um animal;
--   5) as restantes espécies são distribuídas pelos outros recintos da zona,
--      criando recintos com vários animais da mesma espécie e recintos com várias espécies.

WITH zona_ordenada AS (
    SELECT
        r.id_recinto,
        r.id_zona,
        ROW_NUMBER() OVER (
            PARTITION BY r.id_zona
            ORDER BY r.id_recinto
        ) AS pos_recinto
    FROM recinto r
),
especie_com_zona AS (
    SELECT
        e.nome_cientifico,
        e.categoria,
        e.continente,
        COALESCE(
            (
                SELECT z.id_zona
                FROM zona z
                WHERE z.categoria = e.categoria
                  AND z.continente = e.continente
                LIMIT 1
            ),
            (
                SELECT z.id_zona
                FROM zona z
                WHERE z.categoria = e.categoria
                  AND z.continente IS NULL
                LIMIT 1
            ),
            (
                SELECT z.id_zona
                FROM zona z
                WHERE z.categoria IS NULL
                  AND z.continente = e.continente
                LIMIT 1
            )
        ) AS id_zona
    FROM especie e
),
especie_planeada AS (
    SELECT
        ez.*,
        ROW_NUMBER() OVER (
            PARTITION BY ez.id_zona
            ORDER BY ez.nome_cientifico
        ) AS pos_especie_na_zona
    FROM especie_com_zona ez
),
especie_com_recinto AS (
    SELECT
        ep.nome_cientifico,
        zr.id_recinto,
        CASE
            WHEN ep.pos_especie_na_zona = 1 THEN 1
            WHEN ep.pos_especie_na_zona % 10 = 0 THEN 3
            ELSE 2
        END AS n_animais
    FROM especie_planeada ep
    JOIN zona_ordenada zr
      ON zr.id_zona = ep.id_zona
     AND zr.pos_recinto =
         CASE
             WHEN ep.pos_especie_na_zona = 1 THEN 1
             ELSE 2 + ((ep.pos_especie_na_zona - 2) % 11)
         END
)
INSERT INTO animal (nome, nome_cientifico, id_recinto, data_nasc)
SELECT
    'Animal ' || g.n AS nome,
    er.nome_cientifico,
    er.id_recinto,
    DATE '2015-01-01'
        + ((ROW_NUMBER() OVER (ORDER BY er.nome_cientifico, g.n))::INTEGER % 3500)
FROM especie_com_recinto er
CROSS JOIN LATERAL generate_series(1, er.n_animais) AS g(n)
ORDER BY er.nome_cientifico, g.n;


-- ============================================================
-- 05_vendas_bilhetes_acessos.sql
-- ============================================================

-- Exercício 2.5 — Vendas, bilhetes, acessos e votos
-- Este bloco usa uma única transação porque a RI-4 exige que venda,
-- bilhete e acesso formem uma unidade lógica completa.
-- A aula de transações justifica este padrão: várias instruções SQL
-- que representam uma operação lógica devem ser envolvidas por BEGIN/COMMIT.

BEGIN;

-- Plano determinístico de bilhetes:
--   dias úteis: 1000 bilhetes;
--   fins de semana: 4000 bilhetes;
--   50% com desconto 0.50 e 50% com desconto 0.00;
--   75% com votou TRUE;
--   NIF sintético e único para permitir ligar vendas ao plano.
CREATE TEMP TABLE _ticket_plan ON COMMIT DROP AS
WITH dias AS (
    SELECT
        d::DATE AS data,
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
        + ((bilhete_no_dia % 10) * INTERVAL '1 hour')
        + ((bilhete_no_dia % 60) * INTERVAL '1 minute') AS data_hora,
    LPAD((100000000 + ticket_seq)::TEXT, 9, '0') AS nif_cliente,
    CASE
        WHEN bilhete_no_dia % 2 = 0 THEN 0.50::NUMERIC(4,2)
        ELSE 0.00::NUMERIC(4,2)
    END AS desconto,
    (bilhete_no_dia % 4 <> 0) AS votou
FROM numerada;

-- Uma venda por bilhete. Isto simplifica a prova da RI-4:
-- cada venda fica associada a um bilhete que terá acessos.
INSERT INTO venda (data_hora, nif_cliente)
SELECT data_hora, nif_cliente
FROM _ticket_plan
ORDER BY ticket_seq;

INSERT INTO bilhete (desconto, votou, no_venda)
SELECT
    p.desconto,
    p.votou,
    v.no_venda
FROM _ticket_plan p
JOIN venda v
  ON v.nif_cliente = p.nif_cliente
ORDER BY p.ticket_seq;

-- Tabela auxiliar de zonas numeradas.
CREATE TEMP TABLE _zona_ord ON COMMIT DROP AS
SELECT
    id_zona,
    ROW_NUMBER() OVER (ORDER BY id_zona) - 1 AS idx
FROM zona
ORDER BY id_zona;

-- Todas as combinações de 3 ou mais zonas.
CREATE TEMP TABLE _combo ON COMMIT DROP AS
WITH n AS (
    SELECT COUNT(*)::INTEGER AS n_zonas FROM _zona_ord
),
masks AS (
    SELECT generate_series(1, (1 << n_zonas) - 1) AS mask
    FROM n
),
validas AS (
    SELECT m.mask
    FROM masks m
    JOIN _zona_ord z
      ON (m.mask & (1 << z.idx)) <> 0
    GROUP BY m.mask
    HAVING COUNT(*) >= 3
)
SELECT
    ROW_NUMBER() OVER (ORDER BY mask) AS combo_idx,
    mask
FROM validas;

CREATE TEMP TABLE _combo_zona ON COMMIT DROP AS
SELECT
    c.combo_idx,
    z.id_zona
FROM _combo c
JOIN _zona_ord z
  ON (c.mask & (1 << z.idx)) <> 0;

-- Acessos:
--   pelo menos 2% dos bilhetes de cada dia têm acesso total;
--   os restantes percorrem ciclicamente todas as combinações de 3+ zonas.
INSERT INTO acesso (bid, id_zona)
SELECT
    b.bid,
    z.id_zona
FROM _ticket_plan p
JOIN venda v
  ON v.nif_cliente = p.nif_cliente
JOIN bilhete b
  ON b.no_venda = v.no_venda
JOIN _zona_ord z
  ON TRUE
WHERE p.bilhete_no_dia <= CEIL(p.n_bilhetes * 0.02)

UNION ALL

SELECT
    b.bid,
    cz.id_zona
FROM _ticket_plan p
JOIN venda v
  ON v.nif_cliente = p.nif_cliente
JOIN bilhete b
  ON b.no_venda = v.no_venda
JOIN _combo c
  ON c.combo_idx = 1 + ((p.ticket_seq - 1) % (SELECT COUNT(*) FROM _combo))
JOIN _combo_zona cz
  ON cz.combo_idx = c.combo_idx
WHERE p.bilhete_no_dia > CEIL(p.n_bilhetes * 0.02);

-- Atualização dos votos:
--   soma global dos votos = número de bilhetes com votou TRUE;
--   distribuição quase uniforme por recinto;
--   cada recinto recebe muito mais do que 0.1% dos votos totais
--   dado o volume mínimo de bilhetes exigido.
WITH parametros AS (
    SELECT COUNT(*)::INTEGER AS total_votos
    FROM bilhete
    WHERE votou
),
recintos AS (
    SELECT
        id_recinto,
        ROW_NUMBER() OVER (ORDER BY id_recinto)::INTEGER AS rn,
        COUNT(*) OVER ()::INTEGER AS n_recintos
    FROM recinto
),
plano AS (
    SELECT
        r.id_recinto,
        (p.total_votos / r.n_recintos)
        + CASE
            WHEN r.rn <= (p.total_votos % r.n_recintos) THEN 1
            ELSE 0
          END AS votos_calculados
    FROM recintos r
    CROSS JOIN parametros p
)
UPDATE recinto r
SET votos = p.votos_calculados
FROM plano p
WHERE p.id_recinto = r.id_recinto;

COMMIT;
