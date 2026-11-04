class_name Dados
extends RefCounted
## Lê o conteúdo aprovado. Procura primeiro em res://dados/ (versão exportada)
## e depois na pasta conteudo/ do repositório, ao lado de godot/.

static var _cache := {}


static func _pasta_conteudo() -> String:
	if DirAccess.dir_exists_absolute("res://dados"):
		return "res://dados"
	return ProjectSettings.globalize_path("res://").path_join("../conteudo").simplify_path()


static func ler_json(relativo: String) -> Variant:
	if _cache.has(relativo):
		return _cache[relativo]
	var caminho := _pasta_conteudo().path_join(relativo)
	# Na versão exportada (web), o Godot guarda os .json como recurso convertido: lê pelo ResourceLoader.
	if caminho.begins_with("res://") and ResourceLoader.exists(caminho):
		var recurso = ResourceLoader.load(caminho)
		if recurso is JSON:
			_cache[relativo] = recurso.data
			return recurso.data
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		push_error("Não encontrei %s" % caminho)
		return null
	var texto := f.get_as_text()
	if texto.begins_with("﻿"):
		texto = texto.substr(1)
	var dado = JSON.parse_string(texto)
	if dado == null:
		push_error("JSON inválido: %s" % caminho)
	_cache[relativo] = dado
	return dado


static func guardiao(id: String) -> Dictionary:
	var d = ler_json("guardioes/%s.json" % id)
	return d if d is Dictionary else {}


static func itens() -> Dictionary:
	var d = ler_json("itens.json")
	return d if d is Dictionary else {}


static func nomes_computador() -> Array:
	var caminho := _pasta_conteudo().path_join("nomes.json")
	var d = ler_json("nomes.json") if (FileAccess.file_exists(caminho) or ResourceLoader.exists(caminho)) else null
	if d is Dictionary and d.has("nomes"):
		return d["nomes"].map(func(n): return n["nome"])
	return Regras.NOMES_PROVISORIOS.duplicate()
