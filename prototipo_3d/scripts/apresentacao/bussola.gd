extends Control
## Mini bússola no canto da tela. Gira com a câmera: o "N" aponta sempre para o norte do mapa,
## que é o mesmo norte dos avisos ("um uivo vem do norte"). A marca âmbar aponta para a saída.
## No mapa do MVP o norte é -z (para cima no mapa 2D).

const RAIO := 46.0

var camera: Camera3D
var de := Vector2.ZERO          # posição do jogador no mapa
var saida := Vector2.ZERO       # posição da saída no mapa
var mostrar_saida := true

var _fonte: Font


func _ready() -> void:
	custom_minimum_size = Vector2(RAIO * 2.0 + 24.0, RAIO * 2.0 + 24.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fonte = ThemeDB.fallback_font


func _process(_dt: float) -> void:
	queue_redraw()


## Direção do mapa (x, z) -> direção na tela, olhando pela câmera.
func _na_tela(w: Vector2) -> Vector2:
	if camera == null:
		return Vector2(w.x, w.y)
	var f := -camera.global_basis.z
	var r := camera.global_basis.x
	var f2 := Vector2(f.x, f.z)
	if f2.length() < 0.01:
		f2 = Vector2(-camera.global_basis.y.x, -camera.global_basis.y.z)
	f2 = f2.normalized()
	var r2 := Vector2(r.x, r.z).normalized()
	return Vector2(w.dot(r2), -w.dot(f2)).normalized()


func _draw() -> void:
	var c := size / 2.0
	draw_circle(c, RAIO + 6.0, Color(0.04, 0.06, 0.08, 0.72))
	draw_arc(c, RAIO + 6.0, 0, TAU, 48, Color(0.75, 0.7, 0.58, 0.7), 1.5, true)
	# marcas dos rumos intermediários
	for k in 8:
		var ang := k * PI / 4.0
		var w := Vector2(sin(ang), -cos(ang))
		var d := _na_tela(w)
		var curta := k % 2 == 1
		draw_line(c + d * (RAIO - (6.0 if curta else 10.0)), c + d * (RAIO + 2.0), Color(0.75, 0.7, 0.58, 0.55 if curta else 0.8), 1.5, true)
	# saída
	if mostrar_saida and saida.distance_to(de) > 1.0:
		var d := _na_tela((saida - de).normalized())
		var ponta := c + d * (RAIO - 2.0)
		var base := c + d * (RAIO - 16.0)
		var lado := d.orthogonal() * 6.0
		draw_colored_polygon(PackedVector2Array([ponta, base + lado, base - lado]), Color("#E89A3C"))
	# letras N, L, S, O
	var letras := {"N": Vector2(0, -1), "L": Vector2(1, 0), "S": Vector2(0, 1), "O": Vector2(-1, 0)}
	for l in letras:
		var d := _na_tela(letras[l])
		var tam := 18 if l == "N" else 14
		var cor := Color(0.9, 0.35, 0.28) if l == "N" else Color(0.88, 0.85, 0.76)
		var p := c + d * (RAIO - 22.0)
		var largura := _fonte.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		draw_string(_fonte, p + Vector2(-largura / 2.0, tam * 0.36), l, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)
	# agulha do norte
	var dn := _na_tela(Vector2(0, -1))
	draw_line(c, c + dn * 12.0, Color(0.9, 0.35, 0.28), 2.0, true)
	draw_circle(c, 2.5, Color(0.88, 0.85, 0.76))
