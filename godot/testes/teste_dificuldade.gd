extends SceneTree
## Mede a facilidade das visitas: jogador "esperto" (melhor resposta e tom), "bom" (acerta 70%) e "ao acaso".
##   godot --headless --path godot -s res://testes/teste_dificuldade.gd
func _init() -> void:
	var guardioes := ["bento", "iara", "anselmo", "marta", "quincas"]
	for modo in ["esperto", "bom", "ao_acaso"]:
		var sit := {}
		var mente := 0
		var total := 0
		for semente in range(200):
			var m := Mundo.new()
			m.iniciar(semente, {"nome": "T", "atributos": {"forca": 2, "inteligencia": 3, "carisma": 3, "furtividade": 2, "resistencia": 2}})
			var j := m.jogador()
			var g: String = guardioes[semente % 5]
			var v := Visita.new(m, j, g)
			while not v.terminou_perguntas():
				var e := v.pergunta_atual()
				var escolha := "silencio"
				var tom := "gentil"
				if modo == "esperto" or (modo == "bom" and m.rng.randf() < 0.7):
					var melhor := -99
					for o in v.opcoes():
						var r: Dictionary = e["opcao_extra"] if o["chave"] == "extra" else e["respostas"][int(o["chave"])]
						var ok: bool = not e.get("verificavel", false) or m.resposta_verdadeira(j, g, e["id"], o["chave"])
						for t in Regras.TONS:
							var val := int(r["afinidade"]) + v._modificador_tom(r, t) if ok else -4
							if val > melhor:
								melhor = val
								escolha = o["chave"]
								tom = t
				else:
					var ops := v.opcoes()
					escolha = ops[m.rng.randi() % ops.size()]["chave"]
					tom = Regras.TONS[m.rng.randi() % 3]
				v.responder(escolha, tom)
			var ind := v.indicar()
			var s := v.situacao()
			sit[g + ":" + s] = sit.get(g + ":" + s, 0) + 1
			total += 1
		print("== ", modo)
		var ks := sit.keys()
		ks.sort()
		print(ks.map(func(k): return "%s %d" % [k, sit[k]]))
	quit()
