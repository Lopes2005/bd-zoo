@app.route("/zona/<int:zona_id>/", methods=("GET",))
def zona_index(zona_id):
    """ Lista os nomes dos animais em cada um dos recintos de uma certa zona"""
    
    #pool.connection grupo de conexoes pre abertas para ser mais rápido
    with pool.connection() as conn:  #conn é a ligação à BD
        with conn.cursor() as cur:  #cur (cursor) leva a query SQL até à BD
            #Executar a query, passando o dic com a zona_id real
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