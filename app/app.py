#!/usr/bin/python3
# Copyright (c) BDist Development Team
# Distributed under the terms of the Modified BSD License.
import os
from logging.config import dictConfig

from flask import Flask, jsonify, request
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from psycopg.rows import namedtuple_row
from psycopg_pool import ConnectionPool

dictConfig(
    {
        "version": 1,
        "formatters": {
            "default": {
                "format": "[%(asctime)s] %(levelname)s in %(module)s:%(lineno)s - %(funcName)20s(): %(message)s",
            }
        },
        "handlers": {
            "wsgi": {
                "class": "logging.StreamHandler",
                "stream": "ext://flask.logging.wsgi_errors_stream",
                "formatter": "default",
            }
        },
        "root": {"level": "INFO", "handlers": ["wsgi"]},
    }
)

RATELIMIT_STORAGE_URI = os.environ.get("RATELIMIT_STORAGE_URI", "memory://")

app = Flask(__name__)
app.config.from_prefixed_env()
log = app.logger
limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=["200 per day", "50 per hour"],
    storage_uri=RATELIMIT_STORAGE_URI,
)

# Use the DATABASE_URL environment variable if it exists, otherwise use the default.
# Use the format postgres://username:password@hostname/database_name to connect to the database.
DATABASE_URL = os.environ.get("DATABASE_URL", "postgres://app:app@postgres/app")  ###ALTERADO PARA O PROJETO

pool = ConnectionPool(
    conninfo=DATABASE_URL,
    kwargs={
        "autocommit": True,  # If True don’t start transactions automatically.
        "row_factory": namedtuple_row,
    },
    min_size=4,
    max_size=10,
    open=True,
    # check=ConnectionPool.check_connection,
    name="postgres_pool",
    timeout=5,
)


def is_decimal(s):
    """Returns True if string is a parseable float number."""
    try:
        float(s)
        return True
    except ValueError:
        return False


@app.route("/", methods=("GET",))
@app.route("/accounts", methods=("GET",))
@limiter.limit("1 per second")
def account_index():
    """Show all the accounts, most recent first."""

    with pool.connection() as conn:
        with conn.cursor() as cur:
            accounts = cur.execute(
                """
                SELECT account_number, branch_name, balance
                FROM account
                ORDER BY account_number DESC;
                """,
                {},
            ).fetchall()
            log.debug(f"Found {cur.rowcount} rows.")

    return jsonify(accounts), 200


@app.route("/accounts/<account_number>/update", methods=("GET",))
@limiter.limit("1 per second")
def account_update_view(account_number):
    """Show the page to update the account balance."""

    with pool.connection() as conn:
        with conn.cursor() as cur:
            account = cur.execute(
                """
                SELECT account_number, branch_name, balance
                FROM account
                WHERE account_number = %(account_number)s;
                """,
                {"account_number": account_number},
            ).fetchone()
            log.debug(f"Found {cur.rowcount} rows.")

    # At the end of the `connection()` context, the transaction is committed
    # or rolled back, and the connection returned to the pool.

    if account is None:
        return jsonify({"message": "Account not found.", "status": "error"}), 404

    return jsonify(account), 200


@app.route(
    "/accounts/<account_number>/update",
    methods=(
        "PUT",
        "POST",
    ),
)
def account_update_save(account_number):
    """Update the account balance."""

    balance = request.args.get("balance")

    error = None

    if not balance:
        error = "Balance is required."
    if not is_decimal(balance):
        error = "Balance is required to be decimal."

    if error is not None:
        return jsonify({"message": error, "status": "error"}), 400
    else:
        with pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    UPDATE account
                    SET balance = %(balance)s
                    WHERE account_number = %(account_number)s;
                    """,
                    {"account_number": account_number, "balance": balance},
                )
                # The result of this statement is persisted immediately by the database
                # because the connection is in autocommit mode.
                log.debug(f"Updated {cur.rowcount} rows.")

                if cur.rowcount == 0:
                    return (
                        jsonify({"message": "Account not found.", "status": "error"}),
                        404,
                    )

        # The connection is returned to the pool at the end of the `connection()` context but,
        # because it is not in a transaction state, no COMMIT is executed.

        return "", 204


@app.route(
    "/accounts/<account_number>/delete",
    methods=(
        "DELETE",
        "POST",
    ),
)
def account_delete(account_number):
    """Delete the account."""

    with pool.connection() as conn:
        with conn.cursor() as cur:
            try:
                with conn.transaction():
                    # BEGIN is executed, a transaction started
                    cur.execute(
                        """
                        DELETE FROM depositor
                        WHERE account_number = %(account_number)s;
                        """,
                        {"account_number": account_number},
                    )
                    cur.execute(
                        """
                        DELETE FROM account
                        WHERE account_number = %(account_number)s;
                        """,
                        {"account_number": account_number},
                    )
                    # These two operations run atomically in the same transaction
            except Exception as e:
                return jsonify({"message": str(e), "status": "error"}), 500
            else:
                # COMMIT is executed at the end of the block.
                # The connection is in idle state again.
                log.debug(f"Deleted {cur.rowcount} rows.")

                if cur.rowcount == 0:
                    return (
                        jsonify({"message": "Account not found.", "status": "error"}),
                        404,
                    )

    # The connection is returned to the pool at the end of the `connection()` context

    return "", 204


@app.route("/ping", methods=("GET",))
@limiter.exempt
def ping():
    log.debug("ping!")
    return jsonify({"message": "pong!", "status": "success"})


if __name__ == "__main__":
    app.run()



###---FUNÇÔES PARA O PROJETO---###

#DESENVOLVIMENTO DA APLICAÇÃO

@app.route("/zona/<int:zona_id>/", methods=("GET",))
def zona_index(zona_id):
    
    # pool.connection grupo de conexões pré-abertas para ser mais rápido
    with pool.connection() as conn:  # conn é a ligação à BD
        with conn.cursor() as cur:   # cur (cursor) leva a query SQL até à BD
            # Executar a query, passando o dic com a zona_id real
            cur.execute(
                """
                SELECT 
                    r.id_recinto,
                    e.nome_cientifico,
                    e.nome_comum,
                    COUNT(a.id_animal) as numero_animais
                FROM recinto r
                JOIN animal a ON r.id_recinto = a.id_recinto
                JOIN especie e ON a.nome_cientifico = e.nome_cientifico
                WHERE r.id_zona = %(zona_id)s
                GROUP BY r.id_recinto, e.nome_cientifico, e.nome_comum
                ORDER BY r.id_recinto; 
                """,
                {"zona_id": zona_id}
            )
            # Todas as linhas que a base de dados encontrou
            recintos = cur.fetchall()
    
    # Devolver ao cliente o JSON e o código HTTP 200 (OK "sucesso")
    return jsonify(recintos), 200



@app.route("/recinto/<int:id_recinto>/voto/<int:bid>/", methods=("POST",))
def recinto_voto_save(id_recinto, bid):
    """Regista o voto de um bilhete num recinto especifico"""

    with pool.connection() as conn:
        with conn.cursor() as cur:
            
            # Vamos buscar a info do bilhete
            cur.execute(
                "SELECT votou FROM bilhete WHERE bid = %(bid)s;",
                {"bid": bid}
            )
            bilhete = cur.fetchone()

            if bilhete is None:
                #Se o bilhete não existir
                return jsonify({"message": "Erro: Bilhete não encontrado.", "status": "error"}), 404
            
            if bilhete.votou is True:
                #Se o bilhete já tiver votado
                return jsonify({"message": "Erro: Este bilhete já exerceu o seu voto.", "status": "error"}), 400


            # Fazemos um JOIN entre a tabela ACESSO (onde estão as zonas do bilhete)
            # e a tabela RECINTO (para saber a zona do recinto pretendido).
            # Se a query devolver algum resultado, significa que há correspondência e ele tem acesso.
            cur.execute(
                """
                SELECT a.id_zona
                FROM acesso a
                JOIN recinto r ON a.id_zona = r.id_zona
                WHERE a.bid = %(bid)s AND r.id_recinto = %(id_recinto)s;
                """,
                {"bid": bid, "id_recinto": id_recinto}
            )
            tem_acesso = cur.fetchone()

            if tem_acesso is None:
                # Se for None, o bilhete não tem acesso à zona onde está o recinto
                return jsonify({"message": "Erro: O bilhete não tem acesso à zona deste recinto.", "status": "error"}), 403


            #Executar a transação
            try:
                with conn.transaction():
                    cur.execute(
                        "UPDATE bilhete SET votou = TRUE WHERE bid = %(bid)s;",
                        {"bid": bid}

                    )

                    cur.execute(
                        "UPDATE recinto SET votos = votos + 1 WHERE id_recinto = %(id_recinto)s;",
                        {"id_recinto": id_recinto}
                    )

            except Exception as e:
                # Se houver qualquer falha na base de dados durante o UPDATE, a transação faz ROLLBACK automaticamente
                # Envia-se o erro para o cliente
                return jsonify({"message": f"Erro interno na base de dados: {str(e)}", "status": "error"}), 500
            
            else: 
                # Se não houve excepções, a transação faz COMMIT automaticamente 
                # Devolve-se a mensagem de sucesso
                return jsonify({"message": "Voto registado com sucesso!", "status": "success"}), 200


@app.route("/venda/", methods=("POST",))
def venda_save():
    """Executa uma venda de um ou mais bilhetes,
    preenchendo as tabelas venda, bilhete e acesso"""

    #Capturar o pedido em formato JSON
    dados = request.get_json()
    if not dados:
        return jsonify({"message": "Erro: Corpo do pedido JSON não fornecido", "status": "error"}), 400
    
    nif_cliente = dados.get("nif_cliente") #Opcional (pode ser None)
    lista_bilhetes = dados.get("bilhetes") #Lista de bilhetes

    #Validação do input
    if not lista_bilhetes or not isinstance(lista_bilhetes, list):
        return jsonify({"message": "Erro: É necessário uma lista de bilhetes válida.", "status": "error" }), 400

    preco_total_venda = 0.0
    resposta_bilhetes = []

    with pool.connection() as conn:
        with conn.cursor() as cur:
            try:
                # Abrimos uma transação atómica para cumprir os princípios ACID e a RI-4
                with conn.transaction():

                    # Usamos NOW() do PostgreSQL para a data_hora atual
                    cur.execute(
                        """
                        INSERT INTO venda (data_hora, nif_cliente)
                        VALUES (NOW(), %(nif_cliente)s)
                        RETURNING no_venda;
                        """,
                        {"nif_cliente": nif_cliente}
                    )
                    # Como o row_factory é namedtuple_row, acedemos diretamente por ponto (.)
                    no_venda = cur.fetchone().no_venda

                    #Processar cada bilhete individualmente
                    for b in lista_bilhetes:
                        desconto = b.get("desconto", 0.00) #Assume 0 se não for enviado
                        zonas = b.get("zonas") #Lista de IDs de zonas

                        if not zonas or not isinstance(zonas, list):
                            raise Exception("Cada bilhete incluído na venda tem de ter pelo menos acesso a uma zona.")
                        
                        #Inserir registo do Bilhete associado ao no_venda
                        cur.execute(
                            """
                            INSERT INTO bilhete (desconto, votou, no_venda)
                            VALUES (%(desconto)s, FALSE, %(no_venda)s)
                            RETURNING bid;
                            """,
                            {"desconto": desconto, "no_venda": no_venda}
                        )
                        bid = cur.fetchone().bid

                        #Usamos o ANY para ir buscar os preços de todas as zonas deste bilhete
                        # de uma só vez

                        cur.execute(
                            """ 
                            SELECT id_zona, preco
                            FROM zona
                            WHERE id_zona = ANY(%(zonas)s);
                            """,
                            {"zonas": zonas}
                        )
                        zonas_bilhete = cur.fetchall()

                        #Validar se todas as zonas enviadas pelo client existem mesmo
                        if len(zonas_bilhete) != len(set(zonas)):
                            raise Exception("Uma ou mais zonas fornecidas para compra do bilhete são inválidas")

                        preco_base_bilhete = 0.0

                        #Criar acessos e calcular precos
                        for z in zonas_bilhete:
                            #Registar acesso do bilhete àquela zona
                            cur.execute(
                                """
                                INSERT INTO acesso (bid, id_zona)
                                VALUES (%(bid)s, %(id_zona)s);
                                """,
                                {"bid": bid, "id_zona": z.id_zona}
                            )
                            # Somar o preço base desta zona ao total do bilhete
                            preco_base_bilhete += float(z.preco)

                        #Aplicar desconto
                        preco_final_bilhete = round(preco_base_bilhete * (1.0 - float(desconto)), 2)

                        #Acumular preço final do bilhete à venda inteira
                        preco_total_venda += preco_final_bilhete

                        #Guardar info deste bilhete para o Output em Json
                        resposta_bilhetes.append({
                            "numero": bid,
                            "preco": preco_final_bilhete
                        })

            except Exception as e:
                #Se algo falhar, a transsação faz ROLLBACK automático
                return jsonify({"message": f"Erro ao processar a venda: {str(e)}", "status": "error"}), 500
            
            else:
                #Se o bloco try correr sem exceptions, a transação faz COMMIT
                return jsonify({
                    "preco_total": round(preco_total_venda, 2),
                    "bilhetes": resposta_bilhetes,
                    "status": "success"
                }), 201