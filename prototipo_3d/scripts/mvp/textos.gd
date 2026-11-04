class_name Textos
extends RefCounted
## Preenche os marcadores dos textos ({lado}, {base}, {calcado}, {calcado_par}, {item}, {personagem}, {direcao})
## conforme a tabela de revisoes/2026-10-20_textos_mapa.md.

const ARTIGO_ITEM := {
	"ervas": "um maço de ervas", "carne_seca": "um pedaço de carne seca", "fumo": "um rolo de fumo",
	"lamparina": "uma lamparina", "pano": "um pano de saco", "facao": "um facão",
	"apito": "um apito de taquara", "raiz_amarga": "uma raiz amarga",
}


static func preencher(texto: String, valores: Dictionary) -> String:
	var r := texto
	for k in valores:
		r = r.replace("{%s}" % k, str(valores[k]))
	if r.length() > 0:
		r = r[0].to_upper() + r.substr(1)
	return r


static func item(id: String) -> String:
	return ARTIGO_ITEM.get(id, id)


static func direcao(de: Vector2, para: Vector2) -> String:
	var v := para - de
	if v.length() < 15.0:
		return "bem perto"
	var nomes := ["a leste", "a sudeste", "ao sul", "a sudoeste", "a oeste", "a noroeste", "ao norte", "a nordeste"]
	var setor := wrapi(roundi(v.angle() / (PI / 4.0)), 0, 8)
	return nomes[setor]


## Sorteia um texto de uma lista JSON filtrando por campos (ex.: {"base": "bento", "situacao": "sozinho"}).
static func sortear(lista: Array, filtro: Dictionary, rng: RandomNumberGenerator) -> String:
	var ok := lista.filter(func(x):
		for k in filtro:
			if x.get(k) != filtro[k]:
				return false
		return true)
	if ok.is_empty():
		return ""
	return ok[rng.randi() % ok.size()]["texto"]


## Sinal de um animal (conteudo/textos/animais.json). Sem o arquivo, usa a fala provisória de regras.gd.
static func animal(gatilho: String, rng: RandomNumberGenerator) -> String:
	var d = Dados.ler_json("textos/animais.json")
	var t := sortear(d.get("sinais", []) if d is Dictionary else [], {"gatilho": gatilho}, rng)
	return t if t != "" else Regras.FALAS_ANIMAIS.get(gatilho, "")


## Fala ou gesto de indicação de um guardião (conteudo/textos/indicacao.json).
## campo: fala, nada, verdade, mentira, preco. Sem o arquivo, usa a versão provisória de regras.gd.
static func indicacao(base: String, campo: String, rng: RandomNumberGenerator) -> String:
	var d = Dados.ler_json("textos/indicacao.json")
	if d is Dictionary:
		var lista: Array = d.get("indicacao", {}).get(base, {}).get(campo, [])
		if not lista.is_empty():
			return lista[rng.randi() % lista.size()]
	return Regras.INDICACAO.get(base, {}).get(campo, "")


## O que se lê depois de comer (conteudo/textos/panelas.json).
## resultado: boa, ruim_efeito, ruim_resistiu, ruim_sem_efeito.
static func panela(resultado: String, rng: RandomNumberGenerator) -> String:
	var d = Dados.ler_json("textos/panelas.json")
	if d is Dictionary:
		var lista: Array = d.get("resultados", {}).get(resultado, [])
		if not lista.is_empty():
			return lista[rng.randi() % lista.size()]
	return ""
