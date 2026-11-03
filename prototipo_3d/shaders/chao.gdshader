// Chão: barro vermelho nas trilhas e clareiras, folhas úmidas na mata.
shader_type spatial;

uniform sampler2D mascara : filter_linear, repeat_disable;   // 0 = mata, 1 = aberto
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform vec3 barro : source_color = vec3(0.353, 0.227, 0.18);  // #5A3A2E
uniform vec3 folhas : source_color = vec3(0.14, 0.13, 0.08);
uniform vec3 musgo : source_color = vec3(0.12, 0.2, 0.157);    // #1F3328
uniform float tamanho = 160.0;

varying vec2 wxz;

void vertex() {
	wxz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 uv = wxz / tamanho + 0.5;
	float m = texture(mascara, uv).r;
	float n1 = texture(ruido, wxz * 0.02).r;
	float n2 = texture(ruido, wxz * 0.23).r;
	float n3 = texture(ruido, wxz * 1.7).r;

	float aberto = smoothstep(0.35, 0.65, m + (n2 - 0.5) * 0.35);
	vec3 c_barro = barro * (0.75 + 0.45 * n2) * (0.9 + 0.2 * n3);
	vec3 c_mata = mix(folhas, musgo, n1) * (0.6 + 0.6 * n2) * (0.85 + 0.3 * n3);
	ALBEDO = mix(c_mata, c_barro, aberto);
	// barro úmido brilha um pouco com a lua
	ROUGHNESS = mix(0.95, 0.55 + 0.3 * n3, aberto);
	SPECULAR = mix(0.2, 0.45, aberto);
}
