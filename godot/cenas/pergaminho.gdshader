shader_type canvas_item;
// Pergaminho que aparece onde a névoa se abriu. Fora disso, a noite.
// mascara: 1 pixel por metro; branco = já revelado. O círculo de visão atual vem por uniform.

uniform sampler2D mascara : filter_linear;
uniform sampler2D ruido : repeat_enable, filter_linear;
uniform vec2 tamanho_m;
uniform vec2 jogador_m;
uniform float alcance = 14.0;
uniform vec4 cor_papel : source_color = vec4(0.86, 0.77, 0.58, 1.0);
uniform vec4 cor_mancha : source_color = vec4(0.58, 0.42, 0.24, 1.0);
uniform vec4 cor_noite : source_color = vec4(0.055, 0.078, 0.11, 1.0);

void fragment() {
	vec2 m = UV * tamanho_m;
	float vendo = 1.0 - smoothstep(alcance * 0.55, alcance * 1.15, distance(m, jogador_m));
	float revelado = max(texture(mascara, UV).r, vendo);

	float n1 = texture(ruido, m / 140.0).r;
	float n2 = texture(ruido, m / 38.0 + vec2(0.37, 0.11)).r;
	float n3 = texture(ruido, m / 11.0 + vec2(0.71, 0.53)).r;

	vec3 papel = cor_papel.rgb * (0.86 + 0.2 * n1);
	float mancha = smoothstep(0.6, 0.78, n2) * 0.5 + smoothstep(0.68, 0.86, n3) * 0.22;
	papel = mix(papel, cor_mancha.rgb, mancha);
	// Borda escurecida onde a névoa termina, como papel tostado
	float borda = smoothstep(0.1, 0.5, revelado) * (1.0 - smoothstep(0.5, 0.95, revelado));
	papel = mix(papel, cor_mancha.rgb * 0.55, borda * 0.55);

	vec3 noite = cor_noite.rgb * (0.8 + 0.4 * n1);
	COLOR = vec4(mix(noite, papel, smoothstep(0.06, 0.62, revelado)), 1.0);
}
