// Chão: barro vermelho nas trilhas e clareiras, folhas úmidas na mata.
shader_type spatial;

uniform sampler2D mascara : filter_linear, repeat_disable;   // 0 = mata, 1 = aberto
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform vec3 barro : source_color = vec3(0.353, 0.227, 0.18);  // #5A3A2E
uniform vec3 folhas : source_color = vec3(0.14, 0.13, 0.08);
uniform vec3 musgo : source_color = vec3(0.12, 0.2, 0.157);    // #1F3328
uniform float tamanho = 160.0;

varying highp vec2 wxz;   // highp: no navegador a precisão média fazia listras longe do centro

void vertex() {
	wxz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	highp vec2 uv = wxz / tamanho + 0.5;
	float m = texture(mascara, uv).r;
	float n1 = texture(ruido, fract(wxz * 0.02)).r;
	float n2 = texture(ruido, fract(wxz * 0.23)).r;
	float n3 = texture(ruido, fract(wxz * 1.7)).r;

	float aberto = smoothstep(0.35, 0.65, m + (n2 - 0.5) * 0.35);
	vec3 c_barro = barro * (0.75 + 0.45 * n2) * (0.9 + 0.2 * n3);
	vec3 c_mata = mix(folhas, musgo, n1) * (0.6 + 0.6 * n2) * (0.85 + 0.3 * n3);

	// serapilheira: folhas secas de vários tons, mais densas na mata e espalhadas na beira das trilhas
	float f1 = texture(ruido, fract(wxz * 0.9 + 0.37)).r;
	float f2 = texture(ruido, fract(wxz * 2.1 + 0.71)).r;
	float tom = texture(ruido, fract(wxz * 0.7 + 0.13)).r;
	vec3 folha_seca = mix(vec3(0.3, 0.16, 0.08), vec3(0.32, 0.25, 0.11), tom);   // ferrugem a ocre
	folha_seca = mix(folha_seca, vec3(0.3, 0.27, 0.2), smoothstep(0.6, 0.8, f2) * 0.6);   // folhas acinzentadas, velhas
	float tem_folha = smoothstep(0.35, 0.8, f1) * (1.0 - aberto);
	c_mata = mix(c_mata, folha_seca * (0.75 + 0.3 * n3), tem_folha * 0.6);
	// manchas de musgo vivo na mata, longe da trilha
	float mancha = smoothstep(0.58, 0.7, n1 + (n2 - 0.5) * 0.3) * (1.0 - aberto);
	c_mata = mix(c_mata, vec3(0.16, 0.28, 0.11) * (0.8 + 0.4 * n3), mancha * 0.75);
	// na trilha: algumas folhas soltas e marcas de raízes
	// trilha quase limpa, para as pegadas continuarem legíveis
	vec3 trilha = mix(c_barro, folha_seca, smoothstep(0.55, 0.85, f1) * 0.18);
	trilha *= 1.0 - smoothstep(0.6, 0.9, f2) * 0.1;
	ALBEDO = mix(c_mata, trilha, aberto);
	// barro úmido brilha um pouco com a lua
	ROUGHNESS = mix(0.95, 0.55 + 0.3 * n3, aberto);
	SPECULAR = mix(0.2, 0.45, aberto);
}
