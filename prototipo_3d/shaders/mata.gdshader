// Troncos e folhagem da mata.
// - Cor por instância (MultiMesh) para variar o tom de cada árvore.
// - Balanço leve de vento, maior no alto.
// - "Mata transparente": o que fica entre a câmera e o jogador some em pontilhado,
//   para a mata densa não esconder o personagem. Não vale para a sombra da lua.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;

uniform vec4 cor : source_color = vec4(0.12, 0.2, 0.15, 1.0);
uniform float vento = 1.0;
uniform float aspereza = 0.9;
uniform float translucidez = 0.25;   // folhas deixam passar um pouco da lua
uniform float raio_fade = 8.0;
uniform float rugosidade = 0.0;     // deforma a copa em tufos irregulares (0 nos troncos)

global uniform vec3 jogador_pos;
global uniform vec3 camera_dir;
global uniform float fade_ativo;

varying vec3 wpos;
varying vec3 vcor;

float bayer4(vec2 p) {
	ivec2 i = ivec2(mod(p, 4.0));
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i.y * 4 + i.x]) + 0.5) / 16.0;
}

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float ruido3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x),
	               mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y),
	           mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x),
	               mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

varying float tufo;

void vertex() {
	vcor = COLOR.rgb;
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = max(VERTEX.y, 0.0);
	tufo = ruido3(w * 0.9) * 0.65 + ruido3(w * 2.3) * 0.35;
	VERTEX += NORMAL * (tufo - 0.45) * rugosidade;
	float s = sin(TIME * 0.7 + w.x * 0.21 + w.z * 0.17) + 0.5 * sin(TIME * 1.9 + w.z * 0.5);
	VERTEX.x += s * vento * h * h * 0.0008;
	VERTEX.z += s * vento * h * h * 0.0005;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// tufos claros e escuros quebram a forma das copas; o alto pega mais lua
	float claro = mix(1.0, 0.55 + 0.9 * tufo, step(0.01, rugosidade));
	ALBEDO = cor.rgb * vcor * claro;
	ROUGHNESS = aspereza;
	SPECULAR = 0.25;
	BACKLIGHT = vec3(translucidez) * cor.rgb;

	bool camera_principal = abs(dot(CAMERA_DIRECTION_WORLD, camera_dir)) > 0.995;
	if (fade_ativo > 0.5 && camera_principal) {
		vec3 rel = wpos - jogador_pos;
		float frente = dot(rel, -camera_dir);            // > 0: entre o jogador e a câmera
		vec3 lateral = rel + frente * camera_dir;
		float d = length(lateral);
		if (frente > 0.8) {
			float some = smoothstep(raio_fade, raio_fade * 0.8, d);
			if (some > bayer4(FRAGCOORD.xy)) {
				discard;
			}
		}
	}
}
