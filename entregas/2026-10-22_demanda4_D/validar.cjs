const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const read = p => JSON.parse(fs.readFileSync(path.join(__dirname, p), 'utf8'));
const d = read('guardioes_animais.json');
const anterior = read('../2026-10-22_demanda4/guardioes_animais.json');
const gs = ['bento','iara','anselmo','marta','quincas'];
assert.equal(d.versao_formato,3);
assert.deepEqual(Object.keys(d.guardioes).sort(), [...gs].sort());
const ids = new Set(), textosCobra = new Set();
const faixa = n => assert(Number.isInteger(n) && n >= -4 && n <= 4);
const texto = s => { assert(typeof s === 'string' && s.trim()); assert(!/[{}\ufffd]/u.test(s)); assert(!/\b(Bento|Iara|Anselmo|Marta|Quincas)\b/i.test(s)); };
let verificaveis = 0;
for(const g of gs) {
  const qs = d.guardioes[g]; assert.equal(qs.length,2); let extrasTopo = 0;
  qs.forEach((q,i) => {
    assert.equal(q.id,`${g}_${16+i}`); assert(!ids.has(q.id)); ids.add(q.id);
    assert.equal(q.tipo,'pergunta'); assert.equal(typeof q.verificavel,'boolean');
    assert.deepEqual(q.requer,['animais']); assert.deepEqual(q.premissa,[i===0?'cobra_avisou':'lobo_derrubou']); texto(q.texto);
    assert.equal(q.respostas.length,3);
    q.respostas.forEach(r => { texto(r.texto); faixa(r.afinidade); assert([null,'boa','ma'].includes(r.intencao)); if(i===0){assert(!textosCobra.has(r.texto),'Resposta repetida entre guardiões');textosCobra.add(r.texto);} });
    const af = q.respostas.map(r=>r.afinidade).sort((a,b)=>b-a);
    assert(af[0]-af[1]<=2); faixa(q.silencio.afinidade);
    texto(q.opcao_extra.texto); faixa(q.opcao_extra.afinidade); assert.equal(q.opcao_extra.minimo,4);
    assert(['forca','inteligencia','resistencia','furtividade','carisma'].includes(q.opcao_extra.atributo));
    if(q.opcao_extra.afinidade >= af[0]) extrasTopo++;
    if(q.verificavel){verificaveis++; assert(q.verificacao.includes('Opção extra')); faixa(q.mentira.afinidade);assert(q.mentira.afinidade<Math.min(...af,q.opcao_extra.afinidade));}
    else {assert(!('mentira' in q));assert(!('verificacao' in q));}
    if(i===0){ assert(q.verificavel);assert.equal(q.respostas[2].afinidade,af[0]); }
  });
  assert(extrasTopo<=1);
}
assert.equal(verificaveis,5); assert.equal(ids.size,10);
const afin = (g,i) => d.guardioes[g][0].respostas[i].afinidade;
assert(afin('bento',1)>afin('bento',0)); assert(afin('iara',0)>afin('iara',1));
assert(afin('bento',1)>0 && afin('iara',1)<0 && afin('quincas',1)<0);
assert.equal(new Set(d.guardioes.anselmo[0].respostas.map(r=>r.afinidade)).size,1);
assert.equal(d.guardioes.iara[1].verificavel,false);
assert.equal(d.guardioes.iara[1].silencio.afinidade,anterior.guardioes.iara[1].silencio.afinidade);
for(const g of ['bento','anselmo','marta']) assert.deepEqual(d.guardioes[g][1],anterior.guardioes[g][1]);
const esperado = structuredClone(anterior.guardioes.quincas[1]);
esperado.respostas[2].intencao=null;
esperado.opcao_extra.texto=d.guardioes.quincas[1].opcao_extra.texto;
assert.deepEqual(d.guardioes.quincas[1],esperado);
console.log('OK: 10 perguntas v3; IDs 16/17; 5 verificáveis; afinidades, extras e preservação do escopo conferidos.');
console.log('A avaliação literária e a integração das condições no jogo exigem revisão.');
