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