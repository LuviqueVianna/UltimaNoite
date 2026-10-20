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
