// Validação de estrutura e compatibilidade. A qualidade literária exige leitura.
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process'),assert=require('node:assert/strict');
const dir=__dirname,gs=['bento','iara','anselmo','marta','quincas'];
const read=n=>JSON.parse(fs.readFileSync(path.join(dir,n),'utf8'));
const audit=read('auditoria_editorial.json');
const base=g=>JSON.parse(cp.execFileSync('git',['show',`${audit.base}:conteudo/guardioes/${g}.json`],{cwd:dir,encoding:'utf8'}));
const ds=Object.fromEntries(gs.map(g=>[g,read(`guardioes/${g}.json`)]));
const mecanismos=new Set(['bases_visitadas','jogadores_vistos','esconderijo','aproximacao','rastros','armadilhas','historico_respostas','frases_prontas','animais','inventario']);
const premissas=new Set(['encontrou_lobo','lobo_avancou','encontrou_lobo_ferido','coruja_notou','coruja_avisou','cao_ofereceu_guia','notou_armadilha','acionou_armadilha','viu_jogador','viu_pegadas_alheias','reconhece_calcado','usou_esconderijo','sumiu_na_mata','recebeu_frase','recebeu_frase_panela','recebeu_frase_pedido','viu_jogador_entrar_base','enviou_frase','tem_item','visitou_outra_base','cobra_avisou','cobra_picou','cobra_desviou','lobo_derrubou']);
const atributos=['forca','inteligencia','carisma','furtividade','resistencia'];
const ids=new Set(),relatorio=[];
const int=(n,a=-4,b=4)=>assert(Number.isInteger(n)&&n>=a&&n<=b,`Inteiro fora da faixa: ${n}`);
const text=s=>assert(typeof s==='string'&&s.trim()&&!s.includes('\ufffd'),'Texto vazio ou codificação inválida');
function rcheck(r){text(r.texto);int(r.afinidade);if('intencao'in r)assert([null,'boa','ma'].includes(r.intencao));for(const k of ['registra','contradiz'])if(r[k])r[k].forEach(m=>assert(/^[a-z][a-z0-9_]*$/.test(m)));if(r.tom)Object.values(r.tom).forEach(n=>int(n,-2,2));}
const gap=q=>{const v=q.respostas.map(r=>r.afinidade).sort((a,b)=>b-a);return v[0]-v[1];};
const max=q=>Math.max(...q.respostas.map(r=>r.afinidade));
// Para as verificáveis antigas, só afinidades foram autorizadas neste pacote.
function semAfinidades(v){if(Array.isArray(v))return v.map(semAfinidades);if(v&&typeof v==='object')return Object.fromEntries(Object.entries(v).filter(([k])=>k!=='afinidade').map(([k,x])=>[k,semAfinidades(x)]));return v;}
for(const g of gs){
 const d=ds[g],old=base(g),qs=d.entradas.filter(q=>q.tipo==='pergunta');
 assert.equal(d.guardiao,g);assert.equal(d.versao_formato,3);assert.equal(d.entradas.length,23);assert.equal(qs.length,20);
 assert.deepEqual(d.modificadores_tom,old.modificadores_tom);assert.deepEqual(d.reputacao,old.reputacao);assert.deepEqual(d.entradas.slice(0,3),old.entradas.slice(0,3));
 for(let i=1;i<=23;i++)assert.equal(d.entradas[i-1].id,`${g}_${String(i).padStart(2,'0')}`);
 const velhas=qs.filter(q=>+q.id.split('_')[1]<=17),novas=qs.filter(q=>+q.id.split('_')[1]>=18);
 let extras=0,extrasTopo=0,verificaveis=0;
 for(const q of qs){
  assert(!ids.has(q.id));ids.add(q.id);text(q.texto);assert.equal(typeof q.verificavel,'boolean');assert.equal(q.respostas.length,3);
  if(q.requer)q.requer.forEach(m=>assert(mecanismos.has(m),`${q.id}: mecânica ${m}`));
  if(q.premissa)q.premissa.forEach(p=>assert(premissas.has(p)||/^marca:[a-z][a-z0-9_]*$/.test(p),`${q.id}: premissa ${p}`));
  q.respostas.forEach(rcheck);
  if(q.opcao_extra){extras++;rcheck(q.opcao_extra);assert(atributos.includes(q.opcao_extra.atributo));int(q.opcao_extra.minimo,1,5);if(q.opcao_extra.afinidade>=max(q))extrasTopo++;}
  if(q.silencio)int(q.silencio.afinidade);
  if(q.contradicao)int(q.contradicao.afinidade);
  if(q.verificavel){verificaveis++;text(q.verificacao);int(q.mentira.afinidade);assert(q.mentira.afinidade<Math.min(...q.respostas.map(r=>r.afinidade),q.opcao_extra?.afinidade??4),`Mentira não dói: ${q.id}`);}
  const anterior=old.entradas.find(x=>x.id===q.id);
  if(anterior?.verificavel){assert.deepEqual(semAfinidades(q),semAfinidades(anterior),`Fato/posição/campo alterado em ${q.id}`);q.respostas.forEach((r,i)=>assert.equal(r.texto,anterior.respostas[i].texto));}
  if(anterior&&JSON.stringify(anterior)!==JSON.stringify(q))assert(audit.perguntas[q.id],`Falta linha de auditoria: ${q.id}`);
  if(!anterior)assert(audit.perguntas[q.id]);
 }
 const noGrupo=(lista,n)=>lista.filter(q=>audit.perguntas[q.id]?.choque).length>=n;
 assert(noGrupo(velhas,6),`${g}: menos de 6 dilemas antigos`);assert(noGrupo(novas,3),`${g}: menos de 3 dilemas novos`);
 assert(velhas.filter(q=>gap(q)<=1).length>=10);assert(novas.filter(q=>gap(q)<=1).length>=3);
 const gentis=qs.filter(q=>audit.perguntas[q.id]?.gentil!=null&&q.respostas[audit.perguntas[q.id].gentil].afinidade<=0);
 assert(gentis.length>=4);assert(extrasTopo<=extras/2);
 assert(novas.some(q=>(q.requer||[]).includes('armadilhas')&&(q.premissa||[]).some(p=>['notou_armadilha','acionou_armadilha'].includes(p))));
 for(const q of qs){const n=audit.perguntas[q.id];if(n?.choque){assert(n.est!=null);assert(q.respostas[n.est].afinidade<max(q),`Estereótipo ainda no topo: ${q.id}`);}if(n?.gentil!=null)assert(q.respostas[n.gentil].afinidade<=0);}
 // Ausência honesta do encontro ou do inventário nunca perde para ter o fato.
 assert.equal(d.entradas.find(q=>q.id===`${g}_16`).respostas[2].afinidade,max(d.entradas.find(q=>q.id===`${g}_16`)));
 const cont=d.entradas.find(q=>q.id===`${g}_19`);assert.equal(new Set(cont.respostas.map(r=>r.afinidade)).size,1);
 let externas=0;const fontes=gs.filter(x=>x!==g).flatMap(x=>ds[x].entradas.flatMap(q=>(q.respostas||[]).flatMap(r=>r.registra||[])));
 for(const [m,v] of Object.entries(d.reputacao)){int(v,-2,2);if(fontes.includes(m))externas++;}assert(externas>=3);
 if(g==='iara')assert(verificaveis>qs.length/2,'Iara deve continuar majoritariamente verificável');
 if(g==='marta')assert(qs.filter(q=>q.silencio?.afinidade>0).length>qs.length/2);
 if(g==='anselmo')assert(qs.filter(q=>q.contradicao&&q.respostas.some(r=>r.registra)&&q.respostas.some(r=>r.contradiz)).length>=4);
 relatorio.push({guardiao:g,perguntas:qs.length,dilemas_04_17:velhas.filter(q=>audit.perguntas[q.id]?.choque).length,dilemas_18_23:novas.filter(q=>audit.perguntas[q.id]?.choque).length,gap_ate_1_antigas:velhas.filter(q=>gap(q)<=1).length,gentis_ate_zero:gentis.length,extras_topo:extrasTopo,extras,verificaveis});
}
// Condições novas: conferir faixas e disponibilidade em zero, um e vários disparos.
const vn=read('verificacao_novas.json');assert.equal(vn.versao_formato,1);assert.equal(Object.keys(vn.condicoes).length,5);
for(const g of gs){const c=vn.condicoes[`${g}_19`];assert.deepEqual(Object.keys(c),['0','1','2','extra']);for(const [k,op,val] of [['0','==',0],['1','==',1],['2','>=',2],['extra','>=',1]])assert.deepEqual(c[k],[{fato:'armadilhas_acionadas',op,valor:val}]);for(const n of [0,1,2,4]){const passa=k=>c[k].every(x=>x.op==='=='?n===x.valor:n>=x.valor);assert.equal(['0','1','2'].filter(passa).length,1);assert.equal(passa('extra'),n>=1);}}
assert.equal(ds.quincas.entradas.find(q=>q.id==='quincas_05').respostas[0].afinidade,max(ds.quincas.entradas.find(q=>q.id==='quincas_05')));
const b=read('armadilhas_trilha.json');assert.equal(b.versao_formato,1);assert.equal(b.descobertas.length,6);
for(const c of ['armadilha_notada','armadilha_acionada'])assert.equal(b.descobertas.filter(x=>x.conteudo===c).length,3);
for(const x of b.descobertas){assert(!ids.has(x.id));ids.add(x.id);assert.equal(x.local,'trilha');text(x.texto);assert(x.texto.split(/\s+/u).length<=15);assert(!/[{}]|\b(Bento|Iara|Anselmo|Marta|Quincas|beco|clareira)\b/i.test(x.texto));if(x.conteudo==='armadilha_notada')assert(/desvia|desvio|passa ao lado/.test(x.texto));}
const leiame=fs.readFileSync(path.join(dir,'LEIAME.md'),'utf8');
const linhas=[...leiame.matchAll(/^\| ((?:bento|iara|anselmo|marta|quincas)_\d{2}) \|/gm)].map(m=>m[1]);
assert.equal(linhas.length,Object.keys(audit.perguntas).length);assert.deepEqual(linhas.sort(),Object.keys(audit.perguntas).sort(),'Tabela não cobre exatamente as perguntas alteradas ou novas');
console.log('OK: 5 bancos completos, 100 perguntas, 30 novas, 6 textos de trilha; fatos e posições das verificáveis antigas preservados.');
console.table(relatorio);
console.log('Dilemas e gentileza são classificações editoriais documentadas; o validador confere contagens e afinidades, não prova a leitura literária ou o equilíbrio em partida.');
