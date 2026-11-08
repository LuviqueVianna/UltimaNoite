extends Node3D
## Cena principal do protótipo 3D, agora rodando a noite inteira do MVP:
## mapa sorteado de 450 × 450 m, seis bases, três personagens do computador, pegadas,
## lobo, corujas, cão, cobras e armadilhas. A lógica é a do MVP (scripts/mvp/); esta cena só desenha
## e manda os comandos do jogador. Visitas aos guardiões ainda não têm tela: chegar a uma base não abre conversa.

const Terreno := preload("res://scripts/logica/terreno.gd")
const Vegetacao := preload("res://scripts/apresentacao/vegetacao.gd")
const Bases := preload("res://scripts/apresentacao/bases.gd")
const PegadasView := preload("res://scripts/apresentacao/pegadas_view.gd")
const PersonagemView := preload("res://scripts/apresentacao/personagem_view.gd")
const AnimaisView := preload("res://scripts/apresentacao/animais_view.gd")
const Grilos := preload("res://scripts/apresentacao/grilos.gd")
const Bussola := preload("res://scripts/apresentacao/bussola.gd")
const CHAO_SHADER := preload("res://shaders/chao.gdshader")

const SEMENTE := 7
const ELEVACAO := deg_to_rad(35.0)
const DISTANCIA := 120.0
# terceira pessoa: câmera atrás do ombro, à altura de quem anda pela trilha
const ALTURA_OLHO := 1.65
const OMBRO := 0.45
const SENSIBILIDADE := 0.0025
const SEGUE := 3.0          # quão rápido a câmera volta para trás do personagem quando ele anda
const PAUSA_MOUSE := 1.2    # segundos sem mexer o mouse antes de a câmera voltar a seguir
const AVISO_S := 6.0
const ATRIBUTOS_JOGADOR := {"forca": 2, "inteligencia": 3, "carisma": 2, "furtividade": 3, "resistencia": 2}
# Visuais dos personagens do computador: cada um diferente, para não confundir quem é quem.
const VISUAIS_HOMEM := ["vaqueiro", "roceiro", "velho"]
const VISUAIS_MULHER := ["lavadeira", "senhora"]
const PELES := [Color(0.24, 0.15, 0.1), Color(0.42, 0.29, 0.2), Color(0.62, 0.47, 0.37), Color(0.34, 0.22, 0.15)]


## Corpo que a figura do personagem lê: posição, direção, se anda, se caiu.
class Corpo extends RefCounted:
	var pos := Vector2.ZERO
	var direcao := Vector2(0, 1)
	var andando := false
	var velocidade := 0.0
	var caido := false
	var agachado := false
	var pegar := -1.0         # progresso do gesto de pegar (0..1); -1 = não está pegando
	var pegar_tipo := ""      # "chao" ou "alcancar"

	func atualizar(p, dt: float) -> void:
		var d: Vector2 = p.pos - pos
		andando = d.length() > 0.002
		if andando:
			direcao = d.normalized()
		velocidade = d.length() / maxf(dt, 0.0001)
		pos = p.pos
		caido = p.desmaiado or (p.ferido_s > 0.0 and p.espera > 0.0)
		agachado = p.agachado
		pegar = 1.0 - p.pegando_s / p.duracao_pegar() if p.pegando_s > 0.0 else -1.0
		pegar_tipo = p.pegar_tipo


var mundo                 # Mundo do MVP
var terreno
var pausado := false
var ver_tudo := false
var fade_ativo := true
var terceira := false

var _corpos: Array = []   # Corpo por personagem do MVP
var _figuras: Array = []
var _camera: Camera3D
var _azimute := PI / 4.0
var _azimute_alvo := PI / 4.0
var _zoom := 26.0
var _foco := Vector3.ZERO
var _inclinacao := deg_to_rad(-12.0)
var _distancia_3p := 3.2
var _fade_antes := true
var _desde_mouse := 10.0
var _cam_fixa := {}       # para as capturas: {"pos": Vector3, "alvo": Vector3}
var _ambiente: Environment
var _web := RenderingServer.get_current_rendering_method() == "gl_compatibility"
var _lua: DirectionalLight3D
var _luz_visao: OmniLight3D
var _veg: Node3D
var _pegadas: Node3D
var _animais: Node3D
var _armadilhas := {}     # id -> Node3D
var _vagalumes: GPUParticles3D
var _grilos: Node3D
var _hud: Label
var _ajuda: Label
var _avisos_label: Label
var _avisos: Array = []   # {texto, ate}
var _fim: Label
var _barra_vida: ProgressBar
var _barra_folego: ProgressBar
var _texto_vida: Label
var _bussola: Control
var _clarao: ColorRect       # vermelho na tela quando perde vida; verde quando recupera
var _visiveis := 0
var _escalas := [0.8, 1.0, 1.25, 1.5]   # pedido do usuário (08/11): pegadas menores; padrão 1,0 = tamanho real
var _escala_i := 1
var _tempo_montagem := {}


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	mundo = Mundo.new()
	# cópia: o veneno tira pontos dos atributos, e uma constante não pode ser alterada
	mundo.iniciar(SEMENTE, {"nome": "Você", "atributos": ATRIBUTOS_JOGADOR.duplicate()})
	var t1 := Time.get_ticks_msec()
	terreno = Terreno.new(mundo.mapa, SEMENTE)
	var t2 := Time.get_ticks_msec()
	_montar_ambiente()
	_montar_chao()
	_veg = Vegetacao.new()
	_veg.name = "Mata"
	add_child(_veg)
	_veg.montar(terreno.arvores, terreno.plantas)
	for c in _veg.get_children():
		c.layers = 2
	var t3 := Time.get_ticks_msec()
	_montar_bases()
	_pegadas = PegadasView.new()
	_pegadas.name = "Pegadas"
	_pegadas.mundo = mundo
	add_child(_pegadas)
	_montar_personagens()
	_animais = AnimaisView.new()
	_animais.name = "Animais"
	_animais.mundo = mundo
	add_child(_animais)
	_animais.montar()
	_montar_armadilhas()
	_montar_saida()
	_montar_camera()
	_montar_vagalumes()
	_grilos = Grilos.new()
	_grilos.name = "Grilos"
	_grilos.terreno = terreno
	_grilos.jogador = _corpos[0]
	add_child(_grilos)
	_grilos.montar()
	_montar_hud()
	mundo.aviso.connect(_ao_aviso)
	mundo.som.connect(_tocar_som)
	mundo.chegou_saida.connect(_ao_chegar_saida)
	mundo.amanheceu.connect(_ao_amanhecer)
	mundo.vida_mudou.connect(_ao_mudar_vida)
	mundo.desmaiou.connect(func(p): if p.eh_jogador: _ao_aviso("O veneno venceu: você desmaia na trilha."))
	_tempo_montagem = {"mundo": t1 - t0, "terreno": t2 - t1, "mata": t3 - t2, "total": Time.get_ticks_msec() - t0}
	print("MONTAGEM ", _tempo_montagem, " | árvores ", terreno.arvores.size(), " plantas ", terreno.plantas.size())
	var args := OS.get_cmdline_user_args()
	var i := args.find("--captura")
	if i >= 0:
		_captura(args[i + 1] if i + 1 < args.size() else "user://capturas")


func _camada_2(n: Node) -> void:
	for c in n.get_children():
		if c is VisualInstance3D and not c is Light3D and not c is Decal:
			c.layers = 2
		_camada_2(c)


# ---------------- montagem ----------------

func _montar_ambiente() -> void:
	_ambiente = Environment.new()
	_ambiente.background_mode = Environment.BG_COLOR
	_ambiente.background_color = Color("#0E1A2B")
	_ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_ambiente.ambient_light_color = Color(0.16, 0.24, 0.27)
	_ambiente.ambient_light_energy = 0.6
	_ambiente.tonemap_mode = Environment.TONE_MAPPER_AGX
	_ambiente.tonemap_exposure = 1.15
	_ambiente.ssao_enabled = true
	_ambiente.ssao_radius = 1.5
	_ambiente.ssao_intensity = 2.0
	_ambiente.glow_enabled = true
	_ambiente.glow_intensity = 0.6
	_ambiente.glow_bloom = 0.05
	_ambiente.glow_hdr_threshold = 0.9
	_ambiente.volumetric_fog_enabled = true
	# a névoa fica rente ao chão (FogVolume); o ar acima da mata fica limpo
	_ambiente.volumetric_fog_density = 0.0
	_ambiente.volumetric_fog_albedo = Color(0.62, 0.72, 0.78)
	_ambiente.volumetric_fog_emission = Color(0.015, 0.025, 0.04)
	_ambiente.volumetric_fog_anisotropy = 0.35
	_ambiente.volumetric_fog_length = 120.0
	_ambiente.volumetric_fog_ambient_inject = 0.3
	_ambiente.adjustment_enabled = true
	_ambiente.adjustment_saturation = 0.85
	if _web:
		# no navegador não há névoa volumétrica: névoa de altura, rente ao chão
		_ambiente.volumetric_fog_enabled = false
		_ambiente.fog_enabled = true
		_ambiente.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		_ambiente.fog_light_color = Color(0.09, 0.13, 0.16)
		_ambiente.fog_density = 0.0
		_ambiente.fog_height = 1.2
		_ambiente.fog_height_density = 0.12
		_ambiente.tonemap_exposure = 0.85
		_ambiente.ambient_light_energy = 0.35
		_ambiente.fog_sky_affect = 0.0
		_ambiente.ssao_enabled = false
	else:
		_neblina_volumetrica()
	var we := WorldEnvironment.new()
	we.environment = _ambiente
	add_child(we)
	# lua cheia: canto superior esquerdo da tela, fria, azul-esverdeada, sombras longas
	_lua = DirectionalLight3D.new()
	_lua.light_color = Color(0.6, 0.76, 0.8)
	_lua.light_energy = 1.6
	_lua.shadow_enabled = true
	_lua.directional_shadow_max_distance = 110.0
	if _web:
		_lua.shadow_bias = 0.25
		_lua.shadow_normal_bias = 2.5
	_lua.light_angular_distance = 0.6
	_lua.light_volumetric_fog_energy = 0.6
	add_child(_lua)
	_orientar_lua()


func _neblina_volumetrica() -> void:
	var t: float = mundo.mapa.tamanho.x
	var neblina := FogVolume.new()
	neblina.name = "NeblinaRasteira"
	neblina.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	neblina.size = Vector3(t + 40.0, 7, t + 40.0)
	neblina.position = Vector3(t / 2.0, 2.0, t / 2.0)
	var fm := FogMaterial.new()
	fm.density = 0.07
	fm.albedo = Color(0.62, 0.72, 0.78)
	fm.height_falloff = 0.35
	fm.edge_fade = 0.6
	var dens := NoiseTexture3D.new()
	dens.width = 64
	dens.height = 16
	dens.depth = 64
	dens.seamless = true
	var nd := FastNoiseLite.new()
	nd.frequency = 0.05
	dens.noise = nd
	fm.density_texture = dens
	neblina.material = fm
	add_child(neblina)


func _orientar_lua() -> void:
	# "esquerda e para cima" na tela isométrica = direção oposta à direita da câmera somada ao fundo
	var direita := Vector3(cos(_azimute), 0, -sin(_azimute))
	var fundo := -Vector3(sin(_azimute), 0, cos(_azimute))
	var de := (fundo - direita).normalized()
	var alt := deg_to_rad(42.0)
	var origem := de * cos(alt) + Vector3.UP * sin(alt)
	_lua.look_at_from_position(origem * 50.0, Vector3.ZERO, Vector3.UP)


func _montar_chao() -> void:
	var n: int = terreno.n
	var img := Image.create(n, n, false, Image.FORMAT_L8)
	for j in n:
		for i in n:
			img.set_pixel(i, j, Color.WHITE if terreno.celulas[j * n + i] != terreno.MATA else Color.BLACK)
	var ruido := NoiseTexture2D.new()
	ruido.width = 256
	ruido.height = 256
	ruido.seamless = true
	ruido.generate_mipmaps = true
	var fn := FastNoiseLite.new()
	fn.frequency = 0.03
	fn.fractal_octaves = 4
	ruido.noise = fn
	var mat := ShaderMaterial.new()
	mat.shader = CHAO_SHADER
	mat.set_shader_parameter("mascara", ImageTexture.create_from_image(img))
	mat.set_shader_parameter("ruido", ruido)
	mat.set_shader_parameter("tamanho", terreno.tamanho)
	var plano := PlaneMesh.new()
	plano.size = Vector2(terreno.tamanho, terreno.tamanho)
	var chao := MeshInstance3D.new()
	chao.name = "Chao"
	chao.mesh = plano
	chao.material_override = mat
	chao.position = Vector3(terreno.tamanho / 2.0, 0, terreno.tamanho / 2.0)
	add_child(chao)
	var borda := MeshInstance3D.new()
	var pb := PlaneMesh.new()
	pb.size = Vector2(terreno.tamanho * 3.0, terreno.tamanho * 3.0)
	borda.mesh = pb
	var mb := StandardMaterial3D.new()
	mb.albedo_color = Color(0.03, 0.05, 0.05)
	borda.material_override = mb
	borda.position = Vector3(terreno.tamanho / 2.0, -0.05, terreno.tamanho / 2.0)
	add_child(borda)


func _montar_bases() -> void:
	for b in terreno.casas:
		var c: Dictionary = terreno.casas[b]
		var base := Bases.new()
		base.tipo = b
		base.name = "Base_" + b
		var centro: Vector2 = c["centro"]
		var frente: Vector2 = c["frente"]
		base.position = Vector3(centro.x, 0, centro.y)
		base.rotation.y = atan2(frente.x, frente.y)
		add_child(base)
		_camada_2(base)


func _montar_personagens() -> void:
	for p in mundo.personagens:
		var corpo := Corpo.new()
		corpo.pos = p.pos
		_corpos.append(corpo)
		var v := PersonagemView.new()
		v.personagem = corpo
		v.calcado = p.calcado
		if p.eh_jogador:
			v.estilo = "real"
		else:
			var mulheres := _nomes_femininos()
			var lista: Array = VISUAIS_MULHER if mulheres.has(p.nome) else VISUAIS_HOMEM
			var livre: Array = lista.filter(func(x): return not _visuais_usados.has(x))
			v.estilo = livre[0] if not livre.is_empty() else lista[p.id % lista.size()]
			_visuais_usados.append(v.estilo)
			v.pele = PELES[(p.id * 3 + 1) % PELES.size()]
			v.altura = [0.95, 1.04, 0.92, 1.0][p.id % 4]
		add_child(v)
		_figuras.append(v)
		if p.eh_jogador:
			_luz_visao = OmniLight3D.new()
			_luz_visao.position = Vector3(0, 3.0, 0)
			_luz_visao.light_color = Color(0.55, 0.64, 0.72)
			_luz_visao.light_energy = 1.8
			_luz_visao.omni_range = 10.0
			_luz_visao.light_volumetric_fog_energy = 0.0
			v.add_child(_luz_visao)


var _visuais_usados: Array = []


## Nomes femininos da lista de nomes (os de nome_13 em diante, como no conteúdo do MVP).
func _nomes_femininos() -> Array:
	var d = Dados.ler_json("nomes.json")
	var r := []
	if d is Dictionary:
		for n in d.get("nomes", []):
			if int(String(n["id"]).get_slice("_", 1)) >= 13:
				r.append(n["nome"])
	return r


## Armadilhas: mola de ferro escondida na trilha. Só aparece para quem a notou, ou depois de disparada.
func _montar_armadilhas() -> void:
	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = Color(0.3, 0.28, 0.26)
	ferro.roughness = 0.5
	ferro.metallic = 0.6
	for a in mundo.armadilhas.lista:
		var no := Node3D.new()
		no.position = Vector3(a.pos.x, 0, a.pos.y)
		var aberta := Node3D.new()
		aberta.name = "aberta"
		no.add_child(aberta)
		var fechada := Node3D.new()
		fechada.name = "fechada"
		no.add_child(fechada)
		for lado in [-1, 1]:
			var t := TorusMesh.new()
			t.inner_radius = 0.16
			t.outer_radius = 0.19
			t.rings = 16
			t.ring_segments = 4
			var mi := MeshInstance3D.new()
			mi.mesh = t
			mi.material_override = ferro
			mi.scale = Vector3(1, 1, 0.5)
			mi.position = Vector3(0, 0.03, lado * 0.09)
			aberta.add_child(mi)
			var mf := MeshInstance3D.new()
			mf.mesh = t
			mf.material_override = ferro
			mf.rotation.x = PI / 2 * 0.85 * lado
			mf.scale = Vector3(1, 1, 0.5)
			mf.position = Vector3(0, 0.1, 0)
			fechada.add_child(mf)
		var estaca := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.02
		c.bottom_radius = 0.03
		c.height = 0.3
		estaca.mesh = c
		estaca.material_override = ferro
		estaca.position = Vector3(0.25, 0.1, 0)
		no.add_child(estaca)
		add_child(no)
		_camada_2(no)
		_armadilhas[a.id] = no


## A saída do jogador (o lado oposto do mapa): uma porteira de pau com dois lampiões acesos,
## para ser vista de longe entre as árvores. Chegar nela registra a chegada.
func _montar_saida() -> void:
	var j = mundo.jogador()
	var no: int = j.saida
	var p: Vector2 = mundo.mapa.pos(no)
	# a porteira fica atravessada na trilha que chega ao nó
	var dir := Vector2(0, 1)
	if not mundo.mapa.adj[no].is_empty():
		dir = (p - mundo.mapa.pos(mundo.mapa.adj[no][0].x)).normalized()
	var raiz := Node3D.new()
	raiz.name = "Saida"
	raiz.position = Vector3(p.x, 0, p.y)
	raiz.rotation.y = atan2(dir.x, dir.y)
	add_child(raiz)
	var pau := StandardMaterial3D.new()
	pau.albedo_color = Color(0.36, 0.3, 0.24)
	pau.roughness = 0.95
	var luz := StandardMaterial3D.new()
	luz.albedo_color = Color("#F2C26B")
	luz.emission_enabled = true
	luz.emission = Color("#E89A3C")
	luz.emission_energy_multiplier = 4.0
	for lado in [-1, 1]:
		var poste := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.12
		c.bottom_radius = 0.14
		c.height = 2.6
		poste.mesh = c
		poste.material_override = pau
		poste.position = Vector3(lado * 1.9, 1.3, 0)
		raiz.add_child(poste)
		var lamp := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.22, 0.3, 0.22)
		lamp.mesh = b
		lamp.material_override = luz
		lamp.position = Vector3(lado * 1.9, 2.75, 0)
		raiz.add_child(lamp)
		var omni := OmniLight3D.new()
		omni.light_color = Color("#E89A3C")
		omni.light_energy = 3.0
		omni.omni_range = 12.0
		omni.position = Vector3(lado * 1.9, 2.8, 0.4)
		omni.light_volumetric_fog_energy = 3.0
		raiz.add_child(omni)
	for y in [0.7, 1.3, 1.9]:
		for lado in [-1, 1]:
			var tabua := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(1.7, 0.12, 0.08)
			tabua.mesh = b
			tabua.material_override = pau
			# porteira aberta: as duas folhas giradas para fora
			tabua.position = Vector3(lado * 1.9 - lado * 0.6, y, 0.6)
			tabua.rotation.y = lado * 1.1
			raiz.add_child(tabua)
	# um farol alto e fraco, para dar rumo de longe (a luz atravessa a neblina por cima da mata)
	var farol := OmniLight3D.new()
	farol.light_color = Color("#E89A3C")
	farol.light_energy = 1.5
	farol.omni_range = 40.0
	farol.position = Vector3(0, 14.0, 0)
	farol.light_volumetric_fog_energy = 6.0
	raiz.add_child(farol)
	_camada_2(raiz)


func _montar_camera() -> void:
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = _zoom
	_camera.near = 1.0
	_camera.far = 600.0
	add_child(_camera)
	var j = mundo.jogador()
	_foco = Vector3(j.pos.x, 0, j.pos.y)
	_posicionar_camera(1.0)


## Vagalumes: pontos amarelo-esverdeados que piscam em volta do jogador, rente ao mato.
func _montar_vagalumes() -> void:
	_vagalumes = GPUParticles3D.new()
	_vagalumes.name = "Vagalumes"
	_vagalumes.amount = 140
	_vagalumes.lifetime = 7.0
	_vagalumes.preprocess = 7.0
	_vagalumes.local_coords = false
	_vagalumes.visibility_aabb = AABB(Vector3(-30, -2, -30), Vector3(60, 8, 60))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(22, 1.2, 22)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.3
	pm.gravity = Vector3(0, 0.02, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 4.0
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.12, 0.2, 0.3, 0.45, 0.52, 0.62, 0.8, 0.86, 0.95, 1.0])
	var on := Color(4.0, 4.8, 1.2, 1.0)
	var off := Color(0.0, 0.0, 0.0, 0.0)
	grad.colors = PackedColorArray([off, off, on, off, off, on, off, off, on, off, off])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	_vagalumes.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.12, 0.12)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length() / 7.5
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) ** 1.5))
	m.albedo_texture = ImageTexture.create_from_image(img)
	quad.material = m
	_vagalumes.draw_pass_1 = quad
	add_child(_vagalumes)


func _montar_hud() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	_hud = Label.new()
	_hud.position = Vector2(16, 12)
	_estilo_texto(_hud, Color(0.85, 0.82, 0.74), 15)
	cl.add_child(_hud)
	_avisos_label = Label.new()
	_avisos_label.anchor_left = 0.5
	_avisos_label.anchor_right = 0.5
	_avisos_label.anchor_top = 1.0
	_avisos_label.anchor_bottom = 1.0
	_avisos_label.offset_left = -420
	_avisos_label.offset_right = 420
	_avisos_label.offset_top = -170
	_avisos_label.offset_bottom = -60
	_avisos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avisos_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_avisos_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estilo_texto(_avisos_label, Color(0.93, 0.88, 0.76), 18)
	cl.add_child(_avisos_label)
	_ajuda = Label.new()
	_ajuda.anchor_top = 1.0
	_ajuda.anchor_bottom = 1.0
	_ajuda.position = Vector2(16, -40)
	_estilo_texto(_ajuda, Color(0.7, 0.68, 0.62), 14)
	_ajuda.text = _texto_ajuda()
	cl.add_child(_ajuda)
	var caixa := HBoxContainer.new()
	caixa.anchor_top = 1.0
	caixa.anchor_bottom = 1.0
	caixa.position = Vector2(16, -78)
	caixa.add_theme_constant_override("separation", 10)
	cl.add_child(caixa)
	var rot := Label.new()
	rot.text = "Vida"
	_estilo_texto(rot, Color(0.85, 0.82, 0.74), 15)
	caixa.add_child(rot)
	_barra_vida = ProgressBar.new()
	_barra_vida.custom_minimum_size = Vector2(220, 16)
	_barra_vida.max_value = Regras.VIDA_MAX
	_barra_vida.value = Regras.VIDA_MAX
	_barra_vida.show_percentage = false
	_barra_vida.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.05, 0.06, 0.07, 0.8)
	fundo.border_color = Color(0.6, 0.55, 0.45, 0.6)
	fundo.set_border_width_all(1)
	fundo.set_corner_radius_all(3)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = Color(0.72, 0.2, 0.16)
	cheio.set_corner_radius_all(3)
	_barra_vida.add_theme_stylebox_override("background", fundo)
	_barra_vida.add_theme_stylebox_override("fill", cheio)
	caixa.add_child(_barra_vida)
	_texto_vida = Label.new()
	_estilo_texto(_texto_vida, Color(0.85, 0.82, 0.74), 15)
	caixa.add_child(_texto_vida)
	var rot_f := Label.new()
	rot_f.text = "   Fôlego"
	_estilo_texto(rot_f, Color(0.85, 0.82, 0.74), 15)
	caixa.add_child(rot_f)
	_barra_folego = ProgressBar.new()
	_barra_folego.custom_minimum_size = Vector2(140, 10)
	_barra_folego.max_value = 100.0
	_barra_folego.value = 100.0
	_barra_folego.show_percentage = false
	_barra_folego.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cheio_f := StyleBoxFlat.new()
	cheio_f.bg_color = Color(0.78, 0.72, 0.45)
	cheio_f.set_corner_radius_all(3)
	_barra_folego.add_theme_stylebox_override("background", fundo)
	_barra_folego.add_theme_stylebox_override("fill", cheio_f)
	caixa.add_child(_barra_folego)
	_bussola = Bussola.new()
	_bussola.anchor_left = 1.0
	_bussola.anchor_right = 1.0
	_bussola.offset_left = -136
	_bussola.offset_right = -20
	_bussola.offset_top = 16
	_bussola.offset_bottom = 132
	_bussola.camera = _camera
	cl.add_child(_bussola)
	_clarao = ColorRect.new()
	_clarao.anchor_right = 1.0
	_clarao.anchor_bottom = 1.0
	_clarao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clarao.color = Color(0.7, 0.05, 0.03, 0.0)
	cl.add_child(_clarao)
	_fim = Label.new()
	_fim.anchor_right = 1.0
	_fim.anchor_bottom = 1.0
	_fim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fim.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_estilo_texto(_fim, Color(0.95, 0.9, 0.78), 34)
	_fim.visible = false
	cl.add_child(_fim)


func _estilo_texto(l: Label, cor: Color, tamanho: int) -> void:
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.add_theme_font_size_override("font_size", tamanho)


func _texto_ajuda() -> String:
	if terceira:
		return "WASD/setas: andar · Shift: correr · Ctrl: agachar/esconder · G: pegar do chão · mouse: olhar · roda: aproximar · C: câmera isométrica · Esc: soltar o mouse · N: névoa · L: luz de visão · P: pegadas · V: ver tudo · H: esconder textos"
	return "WASD/setas: andar · Shift: correr · Ctrl: agachar/esconder · G: pegar do chão · roda: zoom · Q/E: girar câmera · C: terceira pessoa · F: mata transparente · N: névoa · L: luz de visão · P: pegadas · V: ver tudo · H: esconder textos"


# ---------------- câmera ----------------

func _posicionar_camera(t: float) -> void:
	if not _cam_fixa.is_empty():
		_camera.look_at_from_position(_cam_fixa["pos"], _cam_fixa["alvo"], Vector3.UP)
		RenderingServer.global_shader_parameter_set("camera_dir", -_camera.global_basis.z)
		return
	if terceira:
		_posicionar_terceira(t)
		return
	var j = mundo.jogador()
	var alvo := Vector3(j.pos.x, 0.8, j.pos.y)
	_foco = _foco.lerp(alvo, t)
	_azimute = lerp_angle(_azimute, _azimute_alvo, t)
	var off := Vector3(sin(_azimute), 0, cos(_azimute)) * cos(ELEVACAO) + Vector3.UP * sin(ELEVACAO)
	_camera.look_at_from_position(_foco + off * DISTANCIA, _foco, Vector3.UP)
	_camera.size = lerp(_camera.size, _zoom, t)
	RenderingServer.global_shader_parameter_set("camera_dir", -_camera.global_basis.z)
	RenderingServer.global_shader_parameter_set("jogador_pos", Vector3(j.pos.x, 1.0, j.pos.y))
	RenderingServer.global_shader_parameter_set("raio_corte", clampf(_camera.size * 0.16, 2.8, 9.0))
	_orientar_lua()


## Câmera atrás do ombro direito. O mouse gira (_azimute) e inclina (_inclinacao).
## A lua fica parada no céu: só a câmera isométrica gira a lua junto.
func _posicionar_terceira(t: float) -> void:
	_azimute = _azimute_alvo
	var j = mundo.jogador()
	var cabeca := Vector3(j.pos.x, ALTURA_OLHO, j.pos.y)
	var atras := Vector3(sin(_azimute), 0, cos(_azimute))
	var direita := Vector3(cos(_azimute), 0, -sin(_azimute))
	var dir_olhar := (-atras * cos(_inclinacao) + Vector3.UP * sin(_inclinacao)).normalized()
	# a câmera não entra na mata: encurta a distância até o primeiro ponto fechado atrás do personagem
	var dist := _distancia_3p
	var k := 0.3
	while k < _distancia_3p:
		var q := cabeca + direita * OMBRO * (k / _distancia_3p) - dir_olhar * k
		if terreno.distancia_ao_aberto(Vector2(q.x, q.z)) > 0.6:
			dist = maxf(0.6, k - 0.3)
			break
		k += 0.25
	var pos := cabeca + direita * OMBRO * (dist / _distancia_3p) - dir_olhar * dist
	pos.y = maxf(pos.y, 0.4)
	_foco = _foco.lerp(pos, t) if t < 1.0 else pos
	_camera.look_at_from_position(_foco, _foco + dir_olhar, Vector3.UP)
	RenderingServer.global_shader_parameter_set("camera_dir", -_camera.global_basis.z)
	RenderingServer.global_shader_parameter_set("jogador_pos", Vector3(j.pos.x, 1.0, j.pos.y))


## Enquanto o personagem anda, a câmera gira aos poucos até ficar atrás dele.
func _seguir_por_tras(dt: float) -> void:
	_desde_mouse += dt
	var c: Corpo = _corpos[0]
	if not c.andando or _desde_mouse < PAUSA_MOUSE:
		return
	if (Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) \
			and not (Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)):
		return
	var atras: float = atan2(-c.direcao.x, -c.direcao.y)
	_azimute_alvo = lerp_angle(_azimute_alvo, atras, 1.0 - exp(-SEGUE * dt))


func _trocar_camera() -> void:
	terceira = not terceira
	if terceira:
		_fade_antes = fade_ativo
		_definir_fade(false)
		_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		_camera.fov = 68.0
		_camera.near = 0.1
		_camera.far = 110.0
		_azimute_alvo = _azimute
		_foco = _camera.global_position
		# névoa azul-esverdeada: os troncos de longe viram silhuetas contra ela
		_ambiente.fog_enabled = true
		_ambiente.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		_ambiente.fog_light_color = Color(0.07, 0.12, 0.13)
		_ambiente.fog_density = 0.03
		_ambiente.fog_sky_affect = 1.0
		_luz_visao.position = Vector3(0, 2.6, 0.6)
		_luz_visao.omni_range = 9.0
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		_definir_fade(_fade_antes)
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_camera.near = 1.0
		_camera.far = 600.0
		_azimute_alvo = round((_azimute - PI / 4.0) / (PI / 2.0)) * (PI / 2.0) + PI / 4.0
		var j = mundo.jogador()
		_foco = Vector3(j.pos.x, 0.8, j.pos.y)
		_ambiente.fog_density = 0.0
		_ambiente.fog_enabled = _web
		if _web:
			_ambiente.fog_light_color = Color(0.09, 0.13, 0.16)
		_luz_visao.position = Vector3(0, 3.0, 0)
		_luz_visao.omni_range = 10.0
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_ajuda.text = _texto_ajuda()
	_posicionar_camera(1.0)


func _definir_fade(ativo: bool) -> void:
	fade_ativo = ativo
	RenderingServer.global_shader_parameter_set("fade_ativo", 1.0 if ativo else 0.0)


# ---------------- laço ----------------

func _process(dt: float) -> void:
	if not pausado:
		_dirigir(dt)
		mundo.tick(dt)
	for k in mundo.personagens.size():
		_corpos[k].atualizar(mundo.personagens[k], dt)
		var p = mundo.personagens[k]
		if k > 0:
			# os outros: vistos dentro do alcance de vista do jogador; dentro de uma base, somem
			var dentro := false
			for b in mundo.visitante:
				if mundo.visitante[b]["id"] == p.id:
					dentro = true
			# quem já registrou a chegada foi embora da mata
			var foi_embora: bool = p.registrou()
			_figuras[k].visible = ver_tudo or (not dentro and not foi_embora and not p.oculto() and mundo.jogador().pos.distance_to(p.pos) <= mundo.jogador().alcance())
			_figuras[k].hesitando = p.espera > 0.0 and p.no_atual >= 0
	if terceira:
		_seguir_por_tras(dt)
	var jp: Vector2 = mundo.jogador().pos
	_vagalumes.position = Vector3(jp.x, 1.0, jp.y)
	_posicionar_camera(min(1.0, dt * 6.0))
	_visiveis = _pegadas.atualizar(dt)
	for a in mundo.armadilhas.lista:
		var no: Node3D = _armadilhas[a.id]
		no.visible = ver_tudo or mundo.armadilhas.visivel_para_jogador(a)
		no.get_node("aberta").visible = not a.disparada
		no.get_node("fechada").visible = a.disparada
	_atualizar_hud()


## Teclado em direção da câmera: o personagem anda livre pelas trilhas e clareiras, como no primeiro protótipo.
## A mata e as casas são parede (desliza ao encostar). As regras (lentidão, derrubado, pegadas) ficam no MVP.
func _dirigir(dt: float) -> void:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.y += 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.y -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		v.x += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1
	var dir := Vector2.ZERO
	if v != Vector2.ZERO:
		var frente := -Vector2(sin(_azimute), cos(_azimute))
		var direita := Vector2(cos(_azimute), -sin(_azimute))
		dir = (frente * v.y + direita * v.x).normalized()
	# Shift: mini corrida (as regras só deixam correr sem lentidão e em pé)
	mundo.jogador().correndo = dir != Vector2.ZERO and Input.is_physical_key_pressed(KEY_SHIFT)
	mundo.mover_jogador_livre(dir, dt, terreno.andavel)


func _unhandled_input(ev: InputEvent) -> void:
	if terceira and ev is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_azimute_alvo -= ev.relative.x * SENSIBILIDADE
		_inclinacao = clampf(_inclinacao - ev.relative.y * SENSIBILIDADE, deg_to_rad(-50.0), deg_to_rad(25.0))
		_desde_mouse = 0.0
	if ev is InputEventMouseButton and ev.pressed:
		if terceira and ev.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			if terceira:
				_distancia_3p = maxf(1.6, _distancia_3p * 0.9)
			else:
				_zoom = max(6.0, _zoom * 0.88)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if terceira:
				_distancia_3p = minf(7.0, _distancia_3p * 1.1)
			else:
				_zoom = min(480.0, _zoom * 1.14)
	if ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.physical_keycode:
			KEY_C:
				_trocar_camera()
			KEY_CTRL:
				# agachar / levantar: agachado é o "sumir na mata"
				var j = mundo.jogador()
				j.agachar(not j.agachado)
			KEY_G:
				# ainda não há itens sinalizados: estica o braço à frente, como quem tenta pegar algo.
				# Com itens, G perto de um item caído vai usar pegar("chao").
				mundo.jogador().pegar("alcancar")
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_Q:
				if not terceira:
					_azimute_alvo -= PI / 2.0
			KEY_E:
				if not terceira:
					_azimute_alvo += PI / 2.0
			KEY_F:
				if not terceira:
					_definir_fade(not fade_ativo)
			KEY_N:
				if _web or terceira:
					_ambiente.fog_enabled = not _ambiente.fog_enabled
				else:
					_ambiente.volumetric_fog_enabled = not _ambiente.volumetric_fog_enabled
			KEY_L:
				_luz_visao.visible = not _luz_visao.visible
			KEY_P:
				_escala_i = (_escala_i + 1) % _escalas.size()
				_pegadas.escala = _escalas[_escala_i]
				_pegadas.reaplicar_escala()
			KEY_V:
				ver_tudo = not ver_tudo
				_pegadas.ver_tudo = ver_tudo
				_animais.ver_tudo = ver_tudo
			KEY_H:
				_hud.visible = not _hud.visible
				_ajuda.visible = _hud.visible


# ---------------- eventos do mundo ----------------

func _ao_aviso(texto: String) -> void:
	_avisos.append({"texto": texto, "ate": mundo.tempo + AVISO_S})
	if _avisos.size() > 4:
		_avisos.pop_front()


## Barulho no ponto do mapa onde aconteceu, com som 3D: mais baixo de longe e do lado de onde veio.
func _tocar_som(evento: String, origem: Vector2) -> void:
	var cfg: Dictionary = Regras.SONS.get(evento, {})
	if cfg.is_empty():
		return
	var arquivos: Array = cfg["arquivos"]
	var stream = load("res://sons/%s.ogg" % arquivos[randi() % arquivos.size()])
	if stream == null:
		return
	var tocador := AudioStreamPlayer3D.new()
	tocador.stream = stream
	tocador.position = Vector3(origem.x, 1.0, origem.y)
	tocador.max_distance = float(cfg["alcance"])
	tocador.unit_size = clampf(float(cfg["alcance"]) * 0.12, 4.0, 60.0)
	tocador.volume_db = 2.0
	tocador.panning_strength = 1.2
	add_child(tocador)
	tocador.finished.connect(tocador.queue_free)
	tocador.play()


func _ao_mudar_vida(p, delta: float) -> void:
	if not p.eh_jogador:
		return
	_clarao.color = Color(0.7, 0.05, 0.03, 0.35) if delta < 0.0 else Color(0.2, 0.6, 0.25, 0.18)


func _ao_chegar_saida(p) -> void:
	mundo.registrar_chegada(p)
	_ao_aviso("Você chegou ao outro lado da mata. Chegada registrada com %d pontos." % p.pontos())


func _ao_amanhecer() -> void:
	var j = mundo.jogador()
	_fim.text = "Amanheceu.\n" + ("Você chegou com %d pontos." % j.pontos() if j.registrou() else "Você não chegou ao outro lado a tempo.")
	_fim.visible = true


func _atualizar_hud() -> void:
	var j = mundo.jogador()
	var t: float = mundo.tempo_restante()
	var perto := []
	for a in mundo.fauna.animais:
		if ver_tudo or mundo.fauna.visivel_para_jogador(a):
			var nome: String = {"lobo": "lobo", "coruja": "coruja", "cao": "cão", "cobra": "cobra"}[a.tipo]
			if a.tipo == "cobra" and not (ver_tudo or mundo.fauna.cobra_vista(a)):
				nome = "folhas mexendo"
			perto.append("%s a %d m" % [nome, int(j.pos.distance_to(a.pos))])
	var estado := []
	if j.lento_s > 0.0:
		estado.append("lento")
	if j.agachado:
		estado.append("agachado, oculto %.0f s" % j.oculto_s if j.oculto_s > 0.0 else "agachado (visível; usos de esconder: %d)" % j.usos_sumir())
	elif j.correndo_de_fato():
		estado.append("correndo")
	elif j.correndo and j.lento_s > 0.0:
		estado.append("lento demais para correr")
	elif j.correndo and j.sem_folego:
		estado.append("sem fôlego")
	if j.doses_veneno > 0:
		estado.append("envenenado (%d)" % j.doses_veneno)
	if j.desmaiado:
		estado.append("desmaiado")
	if j.registrou():
		estado.append("chegada registrada")
	var saida: Vector2 = mundo.mapa.pos(j.saida)
	var rumo := "Saída: chegada registrada" if j.registrou() else "Saída: %d m, %s" % [int(j.pos.distance_to(saida)), Textos.direcao(j.pos, saida)]
	var outros := 0
	for k in range(1, _figuras.size()):
		if _figuras[k].visible:
			outros += 1
	_hud.text = "A Última Noite — protótipo 3D · câmera %s · faltam %d:%02d para o amanhecer\n%d FPS · %d chamadas de desenho · %d mil triângulos · mapa %d × %d m\nMata: %d árvores e plantas · pegadas à vista: %d · outros à vista: %d de %d\n%s · Perto: %s%s" % [
		"em terceira pessoa" if terceira else "isométrica",
		int(t) / 60, int(t) % 60,
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0),
		int(terreno.tamanho), int(terreno.tamanho),
		_veg.total_instancias,
		_visiveis,
		outros, _figuras.size() - 1,
		rumo,
		", ".join(perto) if not perto.is_empty() else "nenhum animal à vista",
		("\nVocê: " + ", ".join(estado)) if not estado.is_empty() else "",
	]
	_bussola.de = j.pos
	_bussola.saida = mundo.mapa.pos(j.saida)
	_bussola.mostrar_saida = not j.registrou()
	_barra_vida.value = lerp(_barra_vida.value, j.vida, 0.2)
	_texto_vida.text = "%d" % int(round(j.vida))
	_barra_folego.value = lerp(_barra_folego.value, j.folego * 100.0, 0.3)
	_barra_folego.modulate = Color(1, 0.55, 0.45) if j.sem_folego else Color.WHITE
	_clarao.color.a = move_toward(_clarao.color.a, 0.0, get_process_delta_time() * 0.5)
	var linhas := []
	_avisos = _avisos.filter(func(a): return a["ate"] > mundo.tempo)
	for a in _avisos:
		linhas.append(a["texto"])
	_avisos_label.text = "\n".join(linhas)


# ---------------- capturas automáticas (teste sem jogador) ----------------

func _foto(pasta: String, nome: String, quadros: int = 6) -> void:
	for k in quadros:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(pasta.path_join(nome + ".png"))
	print("FOTO ", nome, " | chamadas=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		" triangulos=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		" objetos=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))


## Câmera de perspectiva parada num ponto, olhando para outro (só para as capturas).
func _olhar(de: Vector3, para: Vector3) -> void:
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = 62.0
	_camera.near = 0.1
	_camera.far = 140.0
	_ambiente.fog_enabled = true
	_ambiente.fog_light_color = Color(0.07, 0.12, 0.13)
	_ambiente.fog_density = 0.025
	_cam_fixa = {"pos": de, "alvo": para}
	_definir_fade(false)
	_posicionar_camera(1.0)


func _captura(pasta: String) -> void:
	pausado = true
	DirAccess.make_dir_recursive_absolute(pasta)
	_hud.visible = false
	_ajuda.visible = false
	# a noite anda um minuto: os personagens do computador saem das partidas, os animais se mexem
	for k in 600:
		mundo.mover_jogador_livre(Vector2(1, 0.2), 0.1, terreno.andavel)
		mundo.tick(0.1)
	for k in mundo.personagens.size():
		_corpos[k].atualizar(mundo.personagens[k], 0.1)
	ver_tudo = true
	_pegadas.ver_tudo = true
	_animais.ver_tudo = true
	var t: float = terreno.tamanho
	var rapida := OS.get_cmdline_user_args().has("--rapida")   # só algumas fotos, para conferir o visual
	# 1) mapa inteiro, de cima
	_definir_fade(false)
	_zoom = t * 1.05
	_camera.size = _zoom
	_camera.far = 900.0
	var centro := Vector3(t / 2.0, 0, t / 2.0)
	var off := Vector3(sin(_azimute), 0, cos(_azimute)) * cos(ELEVACAO) + Vector3.UP * sin(ELEVACAO)
	_cam_fixa = {"pos": centro + off * 400.0, "alvo": centro}
	_posicionar_camera(1.0)
	if not rapida:
		await _foto(pasta, "01_mapa_inteiro", 10)
	# 2) cada base, vista de quem chega pela trilha
	var ordem := ["iara", "marta"] if rapida else ["bento", "iara", "anselmo", "marta", "quincas", "vazia"]
	var n := 2
	for b in ordem:
		if not terreno.casas.has(b):
			continue
		var c: Dictionary = terreno.casas[b]
		var centro_b: Vector2 = c["centro"]
		var frente: Vector2 = c["frente"]
		var lado := frente.orthogonal()
		var olho: Vector2 = centro_b + frente * 15.0 + lado * 6.0
		var alt := 9.0 if b == "marta" else 3.2
		_olhar(Vector3(olho.x, alt, olho.y), Vector3(centro_b.x, 2.6 if b == "marta" else 1.6, centro_b.y))
		await _foto(pasta, "%02d_base_%s" % [n, b])
		n += 1
	# 3) os animais de perto
	var vistos := {}
	for a in mundo.fauna.animais:
		if rapida:
			break
		if vistos.has(a.tipo):
			continue
		vistos[a.tipo] = true
		var alvo := Vector3(a.pos.x, 2.4 if a.tipo == "coruja" else 0.5, a.pos.y)
		var de := alvo + Vector3(2.6, 1.2 if a.tipo != "coruja" else 0.3, 2.6) * (0.7 if a.tipo == "cobra" else 1.0)
		_olhar(de, alvo)
		await _foto(pasta, "%02d_animal_%s" % [n, a.tipo])
		n += 1
	# 3b) os personagens do computador, de frente
	for k in range(1, mundo.personagens.size()):
		var p = mundo.personagens[k]
		var c: Corpo = _corpos[k]
		var frente: Vector2 = c.direcao
		var olho: Vector2 = p.pos + frente * 3.2 + frente.orthogonal() * 0.8
		_figuras[k].visible = true
		_olhar(Vector3(olho.x, 1.5, olho.y), Vector3(p.pos.x, 1.0, p.pos.y))
		await _foto(pasta, "%02d_personagem_%s" % [n, _figuras[k].estilo])
		n += 1
	# 4) o jogador na trilha, em terceira pessoa
	_cam_fixa = {}
	ver_tudo = false
	_pegadas.ver_tudo = false
	_animais.ver_tudo = false
	_trocar_camera()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var c0: Corpo = _corpos[0]
	_azimute_alvo = atan2(-c0.direcao.x, -c0.direcao.y)
	_inclinacao = deg_to_rad(-8.0)
	_posicionar_camera(1.0)
	await _foto(pasta, "%02d_terceira_pessoa" % n)
	# 5) isométrica perto do jogador
	_trocar_camera()
	_zoom = 30.0
	_camera.size = _zoom
	_definir_fade(true)
	_posicionar_camera(1.0)
	await _foto(pasta, "%02d_isometrica" % (n + 1))
	print("FIM")
	get_tree().quit()
