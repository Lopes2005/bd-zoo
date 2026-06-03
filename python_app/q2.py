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


