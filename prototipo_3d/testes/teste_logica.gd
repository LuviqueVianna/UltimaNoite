extends SceneTree
## Teste da lógica sem tela: mapa, visão e pegadas.
func _init() -> void:
	var M = load("res://scripts/logica/mundo.gd")
	var m = M.new(7)
	var falhas := 0
	print("trilhas=", m.trilhas.size(), " arvores=", m.arvores.size(), " plantas=", m.plantas.size())
	var t: Vector2 = m.ponto_da_trilha(2, 0.55)
	for f in range(56, 100, 4):
		var c: Vector2 = m.ponto_da_trilha(2, f / 100.0)
		print(f, " dist=", snappedf(t.distance_to(c), 0.1), " ve=", m.ve(t, c))
	# o jogador não atravessa a mata nem a cabana
	var p = m.criar_personagem("j", "bota", m.base_pos + Vector2(0, 8))
	for k in 200:
		m.mover(p, Vector2(0, -1), 0.05)
	if m.andavel(p.pos) == false: falhas += 1
	print("parou em ", p.pos, " (cabana vai de y=", m.base_pos.y - 2.6, " a ", m.base_pos.y + 2.6, ")")
	if p.pos.y < m.base_pos.y + 2.5: falhas += 1
	print("pegadas=", m.pegadas.size())
	if m.pegadas.size() < 5: falhas += 1
	# a mata tapa a visão: dois pontos em trilhas diferentes, longe, não se veem
	if m.ve(m.ponto_da_trilha(0, 0.6), m.ponto_da_trilha(3, 0.6)): falhas += 1
	print("FALHAS=", falhas)
	quit(falhas)
