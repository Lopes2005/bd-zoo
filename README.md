# Projeto BD Zoo

Este repositório é a fonte de verdade do grupo para o projeto de Bases de Dados.

## Ideia principal

Este repositório NÃO substitui o ambiente Docker da cadeira.

- `zoo-project-git/` contém as soluções versionadas.
- `app/` e `bdist-workspace/` locais servem para testar.
- O notebook oficial é preenchido manualmente no fim.

## Estrutura

app/                          Aplicação Flask
sql/01_integridade/           RI-1 a RI-4
sql/02_dados/                 Inserts de dados
sql/03_engenharia_dados/      Vista materializada e rentabilidade
sql/04_consultas/             Consultas analíticas
sql/05_indices/               Índices e EXPLAIN ANALYZE
tests/                        Testes SQL e app
docs/                         Documentação auxiliar
images/                       Imagens usadas no notebook

Regra importante

Não desenvolver diretamente no notebook.

O notebook é apenas o documento final de submissão.

As soluções devem ser escritas primeiro nos ficheiros .sql ou .py deste repositório.

Como testar SQL

Cada colega deve copiar os ficheiros SQL para o seu ambiente local:

zoo-project-git/sql/
→
bdist-workspace/work/project/sql/

Depois, dentro do terminal do Jupyter/container:

psql postgresql://app:app@postgres/app -f /home/jovyan/work/project/sql/01_integridade/ri4.sql
Como testar Flask

Copiar:

zoo-project-git/app/
→
LABS/app/

Depois correr o Docker normalmente e testar a aplicação em:

http://localhost:8080
Como trabalhar com Git

Criar branch:

git checkout -b ri4

Fazer alterações.

Commit:

git add .
git commit -m "Implement RI4"

Push:

git push
Entrega final

A entrega no Fénix deve conter apenas:

entrega-bd-02-GG.zip
├── entrega-bd-02-GG.ipynb
└── app/

O conteúdo do notebook é preenchido manualmente copiando as soluções dos ficheiros deste repositório.



---
