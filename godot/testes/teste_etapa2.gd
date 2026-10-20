extends SceneTree
## Testes da etapa 2 (bases e diálogo), sem tela:
##   godot --headless --path godot -s res://testes/teste_etapa2.gd

var falhas := 0


func _init() -> void:
	_testar_dados()
	_testar_visita_roteirizada()
	_testar_noites(6)
	print("RESULTADO: %s" % ("OK" if falhas == 0 else "%d falha(s)" % falhas))
	quit(1 if falhas > 0 else 0)


func _checar(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		printerr("FALHA: " + msg)


func _testar_dados() -> void:
	var ids := {}
	for g in ["bento", "iara", "anselmo", "marta", "quincas"]:
		var d := Dados.guardiao(g)
		_checar(d.get("versao_formato") == 3, "%s não está no formato 3" % g)
		for e in d.get("entradas", []):
			ids[e["id"]] = e
		_checar(Regras.COMPORTAMENTO.has(g) and Regras.INDICACAO.has(g), "%s sem comportamento" % g)
	var cond: Dictionary = Dados.ler_json("guardioes/verificacao.json")["condicoes"]
	for id in cond:
		_checar(ids.has(id) and ids[id].get("verificavel", false), "verificação para pergunta inexistente ou não verificável: %s" % id)
	var janelas: Array = Dados.ler_json("textos/janelas.json")["janelas"]
	_checar(janelas.size() == 50, "janelas: %d" % janelas.size())
	print("Dados: %d entradas de guardiões, %d com verificação" % [ids.size(), cond.size()])


## O jogador visita a Capela, mente sobre quantas bases visitou e deve ser pego.
func _testar_visita_roteirizada() -> void:
	var mundo := Mundo.new()
	mundo.iniciar(42, {"nome": "Teste", "atributos": {"forca": 2, "inteligencia": 3, "carisma": 2, "furtividade": 3, "resistencia": 2}})
	var j := mundo.jogador()
	var v := Visita.new(mundo, j, "anselmo")
	_checar(v.perguntas.size() >= 4, "visita com %d perguntas" % v.perguntas.size())
	# Força a pergunta anselmo_04 (quantas bases visitou antes) e responde "Três ou mais" sem ter visitado nenhuma.
	for e in Dados.guardiao("anselmo")["entradas"]:
		if e["id"] == "anselmo_04":
			v.perguntas = [e]
	v.indice = 0
	var r := v.responder("2", "firme")
	_checar(r["mentiu"], "mentira sobre bases visitadas não foi detectada")
	_checar(r["delta"] == -4 + 1, "afinidade da mentira com tom firme deveria ser -3, foi %d" % r["delta"])
	_checar(j.mentiras == 1, "contador de mentiras não subiu")
	# Indicação e refeição
	var ind := v.indicar()
	_checar(ind.has("acao"), "indicação sem ação")
	var c := v.comer("esquerda")
	_checar(j.bases_visitadas.has("anselmo"), "visita não registrada")
	_checar(c.has("boa"), "refeição sem resultado")
	print("Visita roteirizada: mentira detectada, afinidade final %d, situação %s, ação %s" % [v.afinidade, v.situacao(), ind["acao"]])


func _testar_noites(n: int) -> void:
	var total := {"visitas": 0, "boas": 0, "ruins": 0, "mentiras": 0, "venenos": 0, "chegaram": 0, "personagens": 0}
	for semente in n:
		var mundo := Mundo.new()
		mundo.iniciar(2000 + semente, {"nome": "Teste", "atributos": {"forca": 2, "inteligencia": 3, "carisma": 2, "furtividade": 3, "resistencia": 2}})
		mundo.jogador().eh_jogador = false
		mundo.jogador().perfil = "cauteloso"
		var passos := 0
		while not mundo.terminou and passos < 40000:
			mundo.tick(1.0 / 30.0)
			passos += 1
		_checar(mundo.terminou, "noite %d não terminou" % semente)
		var linha := []
		for p in mundo.personagens:
			var boas: int = p.panelas_boas()
			var ruins: int = p.refeicoes.size() - boas
			total["visitas"] += p.refeicoes.size()
			total["boas"] += boas
			total["ruins"] += ruins
			total["mentiras"] += p.mentiras
			var soma := 0
			for k in Regras.ATRIBUTOS:
				soma += p.atributos[k]
			total["venenos"] += Regras.PONTOS_TOTAIS - soma
			_checar(soma <= Regras.PONTOS_TOTAIS, "atributos acima de 12")
			total["personagens"] += 1
			if p.registrou():
				total["chegaram"] += 1
			linha.append("%s(%s) %d boas/%d ruins %s" % [p.nome, p.perfil, boas, ruins, ("chegou %d:%02d, %d pts" % [int(p.concluiu) / 60, int(p.concluiu) % 60, p.pontos()]) if p.registrou() else "NÃO CHEGOU"])
		print("Noite %d: %s" % [semente, ", ".join(linha)])
	_checar(total["visitas"] > n * 4, "poucas visitas: %d" % total["visitas"])
	_checar(total["chegaram"] >= total["personagens"] * 0.75, "só %d de %d chegaram à saída" % [total["chegaram"], total["personagens"]])
	print("Chegaram à saída: %d de %d" % [total["chegaram"], total["personagens"]])
	print("Total: %d refeições, %d boas, %d ruins, %d pontos perdidos por veneno, %d mentiras" % [
		total["visitas"], total["boas"], total["ruins"], total["venenos"], total["mentiras"]])
