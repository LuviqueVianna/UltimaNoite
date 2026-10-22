// Executar com Node.js. Somente leitura; valida o pacote editorial, não o motor.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const read = n => JSON.parse(fs.readFileSync(path.join(__dirname, n), 'utf8'));
const guardioes = ['bento', 'iara', 'anselmo', 'marta', 'quincas'];
const ids = new Set();
const id = x => { assert(!ids.has(x), `ID repetido: ${x}`); ids.add(x); };
function texto(s, limite, marcadores = []) {
  assert.equal(typeof s, 'string'); assert(s.trim());
  assert(!s.includes('\ufffd'), 'Caractere de substituição');
  assert(!/\b(Bento|Iara|Anselmo|Marta|Quincas)\b/i.test(s), `Nome em texto: ${s}`);
  if (limite) assert(s.trim().split(/\s+/u).length <= limite, `Limite: ${s}`);
  const encontrados = [...s.matchAll(/\{([^{}]+)\}/g)].map(m => m[1]);
  assert.deepEqual(encontrados.sort(), [...marcadores].sort(), `Marcadores: ${s}`);
  assert(!s.replace(/\{[^{}]+\}/g, '').match(/[{}]/), 'Chave solta');
}
const gatilhos = ['lobo_rosna','lobo_desiste','lobo_derruba','lobo_escapou','lobo_ferido','coruja_olha','coruja_avisa','cao_guia','cao_seguindo','cao_chegou','cao_late','cobra_som','cobra_ve','cobra_some','cobra_pica','cobra_resistiu'];
const a = read('animais.json'); assert.equal(a.versao_formato, 1); assert.equal(a.sinais.length, 48);
for (const g of gatilhos) {
  const rows = a.sinais.filter(x => x.gatilho === g); assert.equal(rows.length, 3);
  rows.forEach((x,i) => { id(x.id); assert.equal(x.id, `${g}_0${i+1}`); texto(x.texto, 15, g === 'coruja_avisa' ? ['direcao'] : []); });
}
const b = read('eventos_distancia_cobra.json'); assert.equal(b.versao_formato, 1); assert.equal(b.eventos.length, 4);
b.eventos.forEach(x => { id(x.id); assert.equal(x.gatilho, 'cobra_picou'); texto(x.texto, 12, ['direcao']); });
const c = read('clareiras_cobra.json'); assert.equal(c.versao_formato, 1); assert.equal(c.descobertas.length, 6);
for (const local of ['beco','clareira_vazia']) assert.equal(c.descobertas.filter(x => x.local === local).length, 3);
c.descobertas.forEach(x => { id(x.id); assert.equal(x.conteudo, 'animal_cobra'); texto(x.texto, 15); });
const d = read('guardioes_animais.json'); assert.equal(d.versao_formato, 3); assert.deepEqual(Object.keys(d.guardioes).sort(), [...guardioes].sort());
function afinidade(n) { assert(Number.isInteger(n) && n >= -4 && n <= 4); }
let verificaveis = 0;
for (const g of guardioes) {
  const base = JSON.parse(fs.readFileSync(path.join(__dirname, '../../conteudo/guardioes', `${g}.json`), 'utf8'));
  const maior = Math.max(...base.entradas.map(x => Number(x.id.split('_').pop())));
  const qs = d.guardioes[g]; assert.equal(qs.length, 2);
  assert(qs.some(x => x.premissa.some(p => p.startsWith('cobra_'))));
  assert(qs.some(x => x.premissa.includes('lobo_derrubou')));
  let extrasTopo = 0;
  qs.forEach((q,i) => {
    id(q.id); assert.equal(q.id, `${g}_${maior+i+1}`); assert.equal(q.tipo, 'pergunta');
    texto(q.texto); assert.equal(typeof q.verificavel, 'boolean'); assert.deepEqual(q.requer, ['animais']);
    assert(q.premissa.length); q.premissa.forEach(p => assert(['cobra_avisou','cobra_picou','cobra_desviou','lobo_derrubou'].includes(p)));
    assert.equal(q.respostas.length, 3);
    q.respostas.forEach(r => { texto(r.texto); afinidade(r.afinidade); assert([null,'boa','ma'].includes(r.intencao)); });
    const valores = q.respostas.map(r => r.afinidade).sort((a,b) => b-a); assert(valores[0]-valores[1] <= 2);
    texto(q.opcao_extra.texto); afinidade(q.opcao_extra.afinidade);
    assert(['forca','inteligencia','carisma','furtividade','resistencia'].includes(q.opcao_extra.atributo));
    assert.equal(q.opcao_extra.minimo, 4); afinidade(q.silencio.afinidade);
    if(q.opcao_extra.afinidade >= valores[0]) extrasTopo++;
    if(q.verificavel) { verificaveis++; assert(q.verificacao.trim()); afinidade(q.mentira.afinidade); assert(q.mentira.afinidade < Math.min(...valores, q.opcao_extra.afinidade)); }
    if(q.premissa.includes('cobra_avisou')) assert.equal(q.respostas[2].afinidade, valores[0], 'Sem desfecho não pode perder afinidade');
  });
  assert(extrasTopo <= qs.length / 2);
}
const e = read('indicacao.json'); assert.equal(e.versao_formato, 1); assert.deepEqual(Object.keys(e.indicacao).sort(), [...guardioes].sort());
let indicacoes = 0;
for(const g of guardioes) {
  const campos = ['fala','nada','verdade','mentira', ...(g === 'quincas' ? ['preco'] : [])];
  assert.deepEqual(Object.keys(e.indicacao[g]).sort(), campos.sort());
  for(const [k,rows] of Object.entries(e.indicacao[g])) { assert.equal(rows.length,3); indicacoes += rows.length; rows.forEach(s => texto(s,15,k==='fala'?['lado']:[])); }
}
const f = read('panelas.json'); assert.equal(f.versao_formato,1); assert.deepEqual(Object.keys(f.resultados).sort(), ['boa','ruim_efeito','ruim_resistiu','ruim_sem_efeito'].sort());
Object.values(f.resultados).forEach(rows => { assert.equal(rows.length,3); rows.forEach(s => texto(s,15)); });
console.log(`OK: 48 sinais; 4 eventos; 6 descobertas; 10 perguntas (${verificaveis} verificáveis); ${indicacoes} indicações/gestos; 12 resultados. IDs, marcadores, limites e afinidades conferidos.`);
console.log('Limites: não valida áudio, integração Godot ou qualidade literária; requer revisão editorial.');
