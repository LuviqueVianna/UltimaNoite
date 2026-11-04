extends Node3D
## Cena principal do protótipo técnico 3D.
## A lógica (scripts/logica/mundo.gd) não sabe que está em 3D; esta cena só lê o estado e manda comandos.

const Mundo := preload("res://scripts/logica/mundo.gd")
const Vegetacao := preload("res://scripts/apresentacao/vegetacao.gd")
const Cabana := preload("res://scripts/apresentacao/cabana_bento.gd")
const PegadasView := preload("res://scripts/apresentacao/pegadas_view.gd")
const PersonagemView := preload("res://scripts/apresentacao/personagem_view.gd")
const Grilos := preload("res://scripts/apresentacao/grilos.gd")
const CHAO_SHADER := preload("res://shaders/chao.gdshader")

const ELEVACAO := deg_to_rad(35.0)
const DISTANCIA := 70.0
# terceira pessoa: câmera atrás do ombro, à altura de quem anda pela trilha
const ALTURA_OLHO := 1.65
const OMBRO := 0.45
const SENSIBILIDADE := 0.0025
const SEGUE := 3.0          # quão rápido a câmera volta para trás do personagem quando ele anda
const PAUSA_MOUSE := 1.2    # segundos sem mexer o mouse antes de a câmera voltar a seguir

var mundo
var jogador
var outro
var pausado := false
var ver_tudo := false
var fade_ativo := true
var terceira := false             # false = isométrica (padrão), true = terceira pessoa (tecla C)

var _camera: Camera3D
var _azimute := PI / 4.0
var _azimute_alvo := PI / 4.0
var _zoom := 22.0
var _foco := Vector3.ZERO
var _ambiente: Environment
var _web := RenderingServer.get_current_rendering_method() == "gl_compatibility"
var _neblina: FogVolume
var _lua: DirectionalLight3D
var _luz_visao: OmniLight3D
var _veg: Node3D
var _pegadas: Node3D
var _outro_view: Node3D
var _hud: Label
var _ajuda: Label
var _visiveis := 0
var _escalas := [1.0, 1.5, 2.0]
var _escala_i := 1
var _inclinacao := deg_to_rad(-12.0)   # olhar para baixo (negativo) ou para cima, na terceira pessoa
var _distancia_3p := 3.2
var _fade_antes := true
var _desde_mouse := 10.0
var _vagalumes: GPUParticles3D
var _grilos: Node3D


func _ready() -> void:
	mundo = Mundo.new(7)
	_montar_ambiente()
	_montar_chao()
	_veg = Vegetacao.new()
	_veg.name = "Mata"
	add_child(_veg)
	_veg.montar(mundo.arvores, mundo.plantas)
	for c in _veg.get_children():
		c.layers = 2
	var cabana := Cabana.new()
	cabana.name = "CabanaDoBento"
	cabana.position = Vector3(mundo.base_pos.x, 0, mundo.base_pos.y)
	add_child(cabana)
	_camada_2(cabana)
	_pegadas = PegadasView.new()
	_pegadas.name = "Pegadas"
	_pegadas.mundo = mundo
	add_child(_pegadas)
	mundo.pegada_criada.connect(_pegadas.ao_criar)
	_pegadas_do_dono()
	_montar_personagens()
	_montar_camera()
	_montar_vagalumes()
	_grilos = Grilos.new()
	_grilos.name = "Grilos"
	_grilos.mundo = mundo
	_grilos.jogador = jogador
	add_child(_grilos)
	_grilos.montar()
	_montar_hud()
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
		# o renderizador do navegador clareia mais a cena: compensa
		_ambiente.tonemap_exposure = 0.85
		_ambiente.ambient_light_energy = 0.35
		_ambiente.fog_sky_affect = 0.0
		_ambiente.ssao_enabled = false
	if not _web:
		_neblina_volumetrica()
	var we := WorldEnvironment.new()
	we.environment = _ambiente
	add_child(we)
	# lua cheia: canto superior esquerdo da tela, fria, azul-esverdeada, sombras longas
	_lua = DirectionalLight3D.new()
	_lua.light_color = Color(0.6, 0.76, 0.8)
	_lua.light_energy = 1.6
	_lua.shadow_enabled = true
	_lua.directional_shadow_max_distance = 110.0   # a câmera fica a 70 m: abaixo disso a sombra some
	if _web:
		_lua.shadow_bias = 0.25
		_lua.shadow_normal_bias = 2.5
	_lua.light_angular_distance = 0.6
	_lua.light_volumetric_fog_energy = 0.6
	add_child(_lua)
	_orientar_lua()


func _neblina_volumetrica() -> void:
	var neblina := FogVolume.new()
	_neblina = neblina
	neblina.name = "NeblinaRasteira"
	neblina.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	neblina.size = Vector3(200, 7, 200)
	neblina.position = Vector3(0, 2.0, 0)
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
	# "esquerda e para cima" na tela = direção oposta à direita da câmera somada ao fundo
	var direita := Vector3(cos(_azimute), 0, -sin(_azimute))
	var fundo := -Vector3(sin(_azimute), 0, cos(_azimute))
	var de := (fundo - direita).normalized()
	var alt := deg_to_rad(42.0)
	var origem := de * cos(alt) + Vector3.UP * sin(alt)
	_lua.look_at_from_position(origem * 50.0, Vector3.ZERO, Vector3.UP)


func _montar_chao() -> void:
	var n: int = mundo.N
	var img := Image.create(n, n, false, Image.FORMAT_L8)
	for j in n:
		for i in n:
			img.set_pixel(i, j, Color.WHITE if mundo.celulas[j * n + i] != mundo.MATA else Color.BLACK)
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
	mat.set_shader_parameter("tamanho", mundo.TAMANHO)
	var plano := PlaneMesh.new()
	plano.size = Vector2(mundo.TAMANHO, mundo.TAMANHO)
	var chao := MeshInstance3D.new()
	chao.name = "Chao"
	chao.mesh = plano
	chao.material_override = mat
	add_child(chao)
	# borda: mata escura além do trecho
	var borda := MeshInstance3D.new()
	var pb := PlaneMesh.new()
	pb.size = Vector2(600, 600)
	borda.mesh = pb
	var mb := StandardMaterial3D.new()
	mb.albedo_color = Color(0.03, 0.05, 0.05)
	borda.material_override = mb
	borda.position.y = -0.05
	add_child(borda)


func _pegadas_do_dono() -> void:
	# botinas de quem mora ali, saindo da porta da frente para a trilha oeste
	var porta: Vector2 = mundo.base_pos + Vector2(-0.9, 3.4)
	var destino: Vector2 = mundo.base_pos + Vector2(-11.0, 4.0)
	var dir := (destino - porta).normalized()
	var n := int(porta.distance_to(destino) / mundo.PASSO)
	for k in n:
		var lado := k % 2
		var lat := dir.orthogonal() * (0.13 if lado == 0 else -0.13)
		_pegadas.fixar(porta + dir * k * mundo.PASSO + lat, dir.angle(), "botina", lado)


func _montar_personagens() -> void:
	jogador = mundo.criar_personagem("jogador", "bota", mundo.ponto_da_trilha(0, 0.12))
	var jv := PersonagemView.new()
	jv.personagem = jogador
	jv.estilo = "jovem"
	add_child(jv)
	_luz_visao = OmniLight3D.new()
	_luz_visao.position = Vector3(0, 3.0, 0)
	_luz_visao.light_color = Color(0.55, 0.64, 0.72)
	_luz_visao.light_energy = 1.8
	_luz_visao.omni_range = 10.0
	_luz_visao.light_volumetric_fog_energy = 0.0
	jv.add_child(_luz_visao)
	var rota := PackedVector2Array()
	rota.append_array(mundo.trilhas[2])
	rota.append_array(mundo.trilhas[3])
	outro = mundo.criar_personagem("outro", "descalco", rota[0])
	outro.velocidade = 2.4
	outro.rota = rota
	_outro_view = PersonagemView.new()
	_outro_view.personagem = outro
	_outro_view.estilo = "roceiro"
	add_child(_outro_view)


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
	# cada vagalume pisca duas ou três vezes na vida
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
	_vagalumes.position = Vector3(jogador.pos.x, 1.0, jogador.pos.y)
	add_child(_vagalumes)


func _montar_camera() -> void:
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = _zoom
	_camera.near = 1.0
	_camera.far = 400.0
	add_child(_camera)
	_foco = Vector3(jogador.pos.x, 0, jogador.pos.y)
	_posicionar_camera(1.0)


func _posicionar_camera(t: float) -> void:
	if terceira:
		_posicionar_terceira(t)
		return
	var alvo := Vector3(jogador.pos.x, 0.8, jogador.pos.y)
	_foco = _foco.lerp(alvo, t)
	_azimute = lerp_angle(_azimute, _azimute_alvo, t)
	var off := Vector3(sin(_azimute), 0, cos(_azimute)) * cos(ELEVACAO) + Vector3.UP * sin(ELEVACAO)
	_camera.look_at_from_position(_foco + off * DISTANCIA, _foco, Vector3.UP)
	_camera.size = lerp(_camera.size, _zoom, t)
	RenderingServer.global_shader_parameter_set("camera_dir", -_camera.global_basis.z)
	RenderingServer.global_shader_parameter_set("jogador_pos", Vector3(jogador.pos.x, 1.0, jogador.pos.y))
	# a abertura na mata acompanha o zoom: perto, só as árvores coladas; longe, um pouco mais
	RenderingServer.global_shader_parameter_set("raio_corte", clampf(_camera.size * 0.16, 2.8, 9.0))
	_orientar_lua()


## Câmera atrás do ombro direito. O mouse gira (_azimute) e inclina (_inclinacao).
## A lua fica parada no céu: só a câmera isométrica gira a lua junto, para ela ficar sempre no canto da tela.
func _posicionar_terceira(t: float) -> void:
	_azimute = _azimute_alvo
	var cabeca := Vector3(jogador.pos.x, ALTURA_OLHO, jogador.pos.y)
	var atras := Vector3(sin(_azimute), 0, cos(_azimute))
	var direita := Vector3(cos(_azimute), 0, -sin(_azimute))
	var dir_olhar := (-atras * cos(_inclinacao) + Vector3.UP * sin(_inclinacao)).normalized()
	var alvo := cabeca + direita * OMBRO
	var pos := alvo - dir_olhar * _distancia_3p
	pos.y = maxf(pos.y, 0.4)
	_foco = _foco.lerp(pos, t) if t < 1.0 else pos
	_camera.look_at_from_position(_foco, _foco + dir_olhar, Vector3.UP)
	RenderingServer.global_shader_parameter_set("camera_dir", -_camera.global_basis.z)
	RenderingServer.global_shader_parameter_set("jogador_pos", Vector3(jogador.pos.x, 1.0, jogador.pos.y))


## Enquanto o personagem anda, a câmera gira aos poucos até ficar atrás dele.
## Andando de costas (só S) ela não gira, para não ficar dando voltas; mexer o mouse suspende por um instante.
func _seguir_por_tras(dt: float) -> void:
	_desde_mouse += dt
	if not jogador.andando or _desde_mouse < PAUSA_MOUSE:
		return
	var so_re := (Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) \
		and not (Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	if so_re:
		return
	var atras: float = atan2(-jogador.direcao.x, -jogador.direcao.y)
	_azimute_alvo = lerp_angle(_azimute_alvo, atras, 1.0 - exp(-SEGUE * dt))


func _trocar_camera() -> void:
	terceira = not terceira
	if terceira:
		_fade_antes = fade_ativo
		_definir_fade(false)   # por baixo das copas não é preciso sumir com árvores
		_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		_camera.fov = 68.0
		_camera.near = 0.1
		_camera.far = 110.0
		_azimute_alvo = _azimute
		_foco = _camera.global_position
		# neblina de distância: esconde o fim da mata e poupa o desenho do que está longe
		_ambiente.fog_enabled = true
		_ambiente.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		# névoa azul-esverdeada: os troncos de longe viram silhuetas contra ela, dando fundo e cor à mata
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
		_camera.far = 400.0
		_azimute_alvo = round((_azimute - PI / 4.0) / (PI / 2.0)) * (PI / 2.0) + PI / 4.0
		_foco = Vector3(jogador.pos.x, 0.8, jogador.pos.y)
		_ambiente.fog_density = 0.0
		_ambiente.fog_enabled = _web
		if _web:
			_ambiente.fog_light_color = Color(0.09, 0.13, 0.16)
		_luz_visao.position = Vector3(0, 3.0, 0)
		_luz_visao.omni_range = 10.0
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_posicionar_camera(1.0)


func _montar_hud() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	_hud = Label.new()
	_hud.position = Vector2(16, 12)
	_hud.add_theme_color_override("font_color", Color(0.85, 0.82, 0.74))
	_hud.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_hud.add_theme_font_size_override("font_size", 15)
	cl.add_child(_hud)
	_ajuda = Label.new()
	_ajuda.anchor_top = 1.0
	_ajuda.anchor_bottom = 1.0
	_ajuda.position = Vector2(16, -40)
	_ajuda.add_theme_color_override("font_color", Color(0.7, 0.68, 0.62))
	_ajuda.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_ajuda.add_theme_font_size_override("font_size", 14)
	_ajuda.text = _texto_ajuda()
	cl.add_child(_ajuda)


func _texto_ajuda() -> String:
	if terceira:
		return "WASD/setas: andar · mouse: olhar · roda: aproximar · C: câmera isométrica · Esc: soltar o mouse · N: névoa · L: luz de visão · P: tamanho das pegadas · H: esconder textos"
	return "WASD/setas: andar · roda: zoom · Q/E: girar câmera · C: terceira pessoa · F: mata transparente · N: névoa · L: luz de visão · P: tamanho das pegadas · V: ver tudo · H: esconder textos"


# ---------------- laço ----------------

func _process(dt: float) -> void:
	if not pausado:
		mundo.atualizar(dt)
		mundo.mover(jogador, _entrada(), dt)
		mundo.seguir_rota(outro, dt)
	if terceira:
		_seguir_por_tras(dt)
	_vagalumes.position = Vector3(jogador.pos.x, 1.0, jogador.pos.y)
	_posicionar_camera(min(1.0, dt * 6.0))
	_atualizar_visao(dt)
	_atualizar_hud()


func _atualizar_visao(dt: float) -> void:
	_visiveis = _pegadas.atualizar(dt, jogador.pos, ver_tudo)
	_outro_view.visible = ver_tudo or mundo.ve(jogador.pos, outro.pos)


func _entrada() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.y += 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.y -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		v.x += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1
	if v == Vector2.ZERO:
		return v
	var frente := -Vector2(sin(_azimute), cos(_azimute))
	var direita := Vector2(cos(_azimute), -sin(_azimute))
	return frente * v.y + direita * v.x


func _unhandled_input(ev: InputEvent) -> void:
	if terceira and ev is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_azimute_alvo -= ev.relative.x * SENSIBILIDADE
		_desde_mouse = 0.0
		_inclinacao = clampf(_inclinacao - ev.relative.y * SENSIBILIDADE, deg_to_rad(-50.0), deg_to_rad(25.0))
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
				_zoom = min(110.0, _zoom * 1.14)
	if ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.physical_keycode:
			KEY_C:
				_trocar_camera()
				_ajuda.text = _texto_ajuda()
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_Q:
				if not terceira:
					_azimute_alvo -= PI / 2.0
			KEY_E:
				if not terceira:
					_azimute_alvo += PI / 2.0
			KEY_F:
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
			KEY_H:
				_hud.visible = not _hud.visible
				_ajuda.visible = _hud.visible


func _definir_fade(ativo: bool) -> void:
	fade_ativo = ativo
	RenderingServer.global_shader_parameter_set("fade_ativo", 1.0 if ativo else 0.0)


func _atualizar_hud() -> void:
	_hud.text = "A Última Noite — protótipo técnico 3D · câmera %s\n%d FPS · %d chamadas de desenho · %d mil triângulos\nMata: %d árvores e plantas · pegadas à vista: %d (tamanho %.1fx)\nOutro personagem: %s\nMata transparente: %s · névoa: %s · luz de visão: %s" % [
		"em terceira pessoa" if terceira else "isométrica",
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0),
		_veg.total_instancias,
		_visiveis,
		_pegadas.escala,
		"à vista" if _outro_view.visible else "fora de vista",
		"sim" if fade_ativo else "não",
		"sim" if (_ambiente.fog_enabled if (_web or terceira) else _ambiente.volumetric_fog_enabled) else "não",
		"sim" if _luz_visao.visible else "não",
	]


# ---------------- capturas automáticas (teste sem jogador) ----------------

func _simular(segundos: float, alvo_jogador = null) -> void:
	var passos := int(segundos / 0.05)
	for k in passos:
		mundo.atualizar(0.05)
		mundo.seguir_rota(outro, 0.05)
		if alvo_jogador != null:
			var d: Vector2 = alvo_jogador - jogador.pos
			if d.length() > 0.3:
				mundo.mover(jogador, d, 0.05)
			else:
				jogador.andando = false


func _foto(pasta: String, nome: String, quadros: int = 8) -> void:
	_posicionar_camera(1.0)
	for k in quadros:
		await get_tree().process_frame
		_posicionar_camera(1.0)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(pasta.path_join(nome + ".png"))
	print("FOTO ", nome, " | chamadas=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		" triangulos=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		" objetos=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		" pegadas_vistas=", _visiveis, " outro_visivel=", _outro_view.visible)


func _captura(pasta: String) -> void:
	pausado = true
	DirAccess.make_dir_recursive_absolute(pasta)
	_hud.visible = false
	_ajuda.visible = false
	print("MATA ", _veg.total_instancias, " instancias (", mundo.arvores.size(), " arvores, ", mundo.plantas.size(), " plantas)")
	# o outro personagem anda um tempo; o jogador sai da trilha oeste até a janela da cabana
	_simular(25.0)
	var janela: Vector2 = mundo.base_pos + Vector2(5.2, 2.2)
	var entrada_clareira: Vector2 = mundo.base_pos + Vector2(-9.0, 5.5)
	_simular(12.0, entrada_clareira)
	_simular(8.0, janela)
	_visiveis = _pegadas.atualizar(0.3, jogador.pos, false)
	_outro_view.visible = mundo.ve(jogador.pos, outro.pos)
	_zoom = 26.0
	await _foto(pasta, "01_clareira_cabana", 12)
	_zoom = 9.0
	await _foto(pasta, "02_pegadas_perto")
	# na trilha do sudeste, sob a mata, por onde o outro personagem passou descalço
	var trilha: Vector2 = mundo.ponto_da_trilha(2, 0.55)
	jogador.pos = trilha
	jogador.direcao = (mundo.ponto_da_trilha(2, 0.6) - trilha).normalized()
	_visiveis = _pegadas.atualizar(0.3, jogador.pos, false)
	_outro_view.visible = mundo.ve(jogador.pos, outro.pos)
	_zoom = 20.0
	await _foto(pasta, "03_trilha_sob_a_mata")
	_definir_fade(false)
	await _foto(pasta, "04_trilha_sem_transparencia")
	_definir_fade(true)
	# o outro personagem aparece quando está na linha de visada
	for f in range(56, 100):
		var cand: Vector2 = mundo.ponto_da_trilha(2, f / 100.0)
		if cand.distance_to(trilha) > 5.0 and mundo.ve(trilha, cand):
			outro.pos = cand
	outro.direcao = (trilha - outro.pos).normalized()
	_visiveis = _pegadas.atualizar(0.3, jogador.pos, false)
	_outro_view.visible = mundo.ve(jogador.pos, outro.pos)
	await _foto(pasta, "05_outro_personagem")
	# visão geral da mata
	jogador.pos = mundo.base_pos + Vector2(6, 6)
	_zoom = 75.0
	await _foto(pasta, "06_visao_geral")
	# terceira pessoa: andando pela trilha sob a mata, olhando para a frente
	_trocar_camera()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	jogador.pos = mundo.ponto_da_trilha(2, 0.45)
	var adiante: Vector2 = (mundo.ponto_da_trilha(2, 0.52) - jogador.pos).normalized()
	jogador.direcao = adiante
	_azimute_alvo = atan2(-adiante.x, -adiante.y)
	_inclinacao = deg_to_rad(-6.0)
	_visiveis = _pegadas.atualizar(0.3, jogador.pos, false)
	await _foto(pasta, "07_terceira_trilha")
	# chegando na clareira, a cabana à frente
	jogador.pos = mundo.base_pos + Vector2(-13.0, 7.0)
	var para_cabana: Vector2 = (mundo.base_pos - jogador.pos).normalized()
	jogador.direcao = para_cabana
	_azimute_alvo = atan2(-para_cabana.x, -para_cabana.y)
	_inclinacao = deg_to_rad(-4.0)
	_visiveis = _pegadas.atualizar(0.3, jogador.pos, false)
	await _foto(pasta, "08_terceira_cabana")
	# olhando para cima: as copas fechando o céu
	_inclinacao = deg_to_rad(22.0)
	jogador.pos = mundo.ponto_da_trilha(2, 0.45)
	_azimute_alvo = atan2(-adiante.x, -adiante.y)
	await _foto(pasta, "09_terceira_copas")
	print("FIM")
	get_tree().quit()
