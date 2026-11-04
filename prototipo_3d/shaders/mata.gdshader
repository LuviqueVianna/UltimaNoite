// Troncos e folhagem da mata.
// - Cor por instância (MultiMesh) para variar o tom de cada árvore.
// - Balanço leve de vento, maior no alto.
// - "Mata transparente": cada árvore que fica entre a câmera e o jogador some inteira
//   (tronco e copa juntos), com uma borda suave nas árvores do limite. A sombra continua.
shader_type spatial;
render_mode cull_back, diffuse_lambert_wrap;

uniform vec4 cor : source_color = vec4(0.12, 0.2, 0.15, 1.0);
uniform float vento = 1.0;
uniform float aspereza = 0.9;
uniform float translucidez = 0.25;   // folhas deixam passar um pouco da lua
uniform float altura_copa = 10.0;   // altura típica da espécie, para saber se a copa tapa o jogador
uniform float raio_copa = 2.5;     // quanto a copa se abre para os lados (m)
uniform float corta = 1.0;
uniform float casca = 0.0;          // 0 = folhagem; 1 = casca com sulcos; 2 = anéis (embaúba, palmeira, bambu)          // 0 = nunca some (sub-bosque baixo)
uniform float rugosidade = 0.0;     // deforma a copa em tufos irregulares (0 nos troncos)

global uniform vec3 jogador_pos;
global uniform vec3 camera_dir;
global uniform float fade_ativo;
global uniform float raio_corte;

varying highp vec3 wpos;
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
varying float some;

// Distância lateral (perpendicular à visão) entre um ponto e a linha câmera → jogador.
// Negativa quando o ponto está atrás do jogador (não tapa).
float lateral(vec3 p) {
	vec3 rel = p - jogador_pos;
	float frente = dot(rel, -camera_dir);
	if (frente < 0.6) {
		return 1e5;
	}
	return length(rel + frente * camera_dir);
}

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

	// decisão por árvore inteira: usa a origem da instância, não o pixel
	some = 0.0;
	bool camera_principal = abs(dot(CAMERA_DIRECTION_WORLD, camera_dir)) > 0.995;
	if (fade_ativo > 0.5 && corta > 0.5 && camera_principal) {
		vec3 base = MODEL_MATRIX[3].xyz;
		float esc = length(MODEL_MATRIX[1].xyz);
		float d = 1e5;
		for (int k = 1; k <= 4; k++) {
			d = min(d, lateral(base + vec3(0.0, altura_copa * esc * float(k) / 4.0, 0.0)));
		}
		d -= raio_copa * esc;   // a borda da copa, não o tronco, é que tapa o jogador
		some = smoothstep(raio_corte * 0.6, raio_corte * 0.25, d);
	}
}

void fragment() {
	vec3 base = cor.rgb * vcor;
	vec3 n_mundo = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	if (casca > 0.5) {
		// sulcos verticais (ou anéis), musgo na base e no lado sombreado, manchas de líquen
		float sulco;
		if (casca < 1.5) {
			sulco = ruido3(vec3(wpos.x * 7.0, wpos.y * 0.8, wpos.z * 7.0)) * 0.7 + ruido3(wpos * 3.0) * 0.3;
			base *= 0.6 + 0.65 * sulco;
		} else {
			float anel = fract(wpos.y * 1.4 + ruido3(wpos * 1.5) * 0.35);
			base *= 1.0 - 0.45 * smoothstep(0.82, 0.95, anel);
			base *= 0.85 + 0.3 * ruido3(wpos * 4.0);
		}
		float lado_umido = smoothstep(-0.2, 0.9, dot(n_mundo, normalize(vec3(-0.4, 0.0, -1.0))));
		float altura = 1.0 - smoothstep(0.3, 3.5, wpos.y);
		float musgo = clamp(lado_umido * 0.6 + altura * 0.7, 0.0, 1.0) * smoothstep(0.35, 0.65, ruido3(wpos * 2.2));
		base = mix(base, vec3(0.17, 0.27, 0.11), musgo * 0.7);
		float liquen = smoothstep(0.7, 0.85, ruido3(wpos * 9.0 + 13.0)) * (1.0 - altura * 0.5);
		base = mix(base, vec3(0.42, 0.46, 0.38), liquen * 0.35);
	} else if (rugosidade > 0.01) {
		// copas: tufos claros e escuros e variação de tom entre árvores e dentro da copa
		float claro = 0.55 + 0.9 * tufo;
		float tom = ruido3(wpos * 0.18 + 7.0);
		float frio = ruido3(wpos * 0.6 + 31.0);
		base *= claro;
		base = mix(base, base * vec3(1.3, 1.2, 0.65), smoothstep(0.45, 0.85, tom) * 0.7);   // folhas novas, amareladas
		base = mix(base, base * vec3(0.75, 1.0, 1.15), smoothstep(0.5, 0.9, frio) * 0.5);   // tons azulados
		// a parte de cima pega a lua
		base *= 1.0 + 0.35 * clamp(n_mundo.y, 0.0, 1.0);
	}
	ALBEDO = base;
	ROUGHNESS = aspereza;
	SPECULAR = 0.25;
	BACKLIGHT = vec3(translucidez) * cor.rgb;

	if (some > 0.001 && some > bayer4(FRAGCOORD.xy)) {
		discard;
	}
}
