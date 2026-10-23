extends SceneTree
## Chance de notar uma armadilha pela Inteligência (decidido em 23/10/2026: 0%, 10%, 30%, 50%, 70%).
##   godot --headless --path godot -s res://testes/teste_armadilhas.gd

func _init() -> void:
	var falhas := 0
	for intel in [1, 2, 3, 4, 5]:
		var pisou := 0
		var n := 120
		for k in n:
			var m := Mundo.new()
			m.iniciar(500 + k, {"nome": "Teste", "atributos": {"forca": 3, "inteligencia": intel, "carisma": 2, "furtividade": 3, "resistencia": 1}})
			m.fauna.animais = []
			var j := m.jogador()
			var no := j.no_atual
			var viz: int = m.mapa.adj[no][0].x
			# Uma armadilha no meio do trecho, e o jogador passando por cima dela
			var a := Armadilhas.Armadilha.new()
			a.pos = m.mapa.pos(no).lerp(m.mapa.pos(viz), 0.5)
			m.armadilhas.lista = [a]
			j.ir_para(m.mapa, viz, false)
			for i in 200:
				m.tick(0.05)
				if a.disparada or j.no_atual == viz:
					break
			if a.disparada:
				pisou += 1
		var esperado: float = 1.0 - Regras.nivel(Regras.CHANCE_NOTAR, intel)
		var ok := absf(pisou / float(n) - esperado) < 0.12
		if not ok:
			falhas += 1
		print("  %s Inteligência %d: pisou em %d%% (esperado %d%%)" % ["ok  " if ok else "FALHA", intel, roundi(100.0 * pisou / n), roundi(esperado * 100)])
	print("RESULTADO: ", "OK" if falhas == 0 else "%d FALHA(S)" % falhas)
	quit(1 if falhas > 0 else 0)
