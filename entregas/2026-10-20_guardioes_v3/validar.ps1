$ErrorActionPreference = 'Stop'
$base = $PSScriptRoot
$fora = Join-Path $base 'fora_do_mvp'
$guardioes = @('bento','iara','anselmo','marta','quincas')
$requerMvp = @('bases_visitadas','jogadores_vistos','esconderijo','aproximacao','rastros','armadilhas','historico_respostas','frases_prontas','animais','inventario')
$requerFora = @('trocas','prendas','escuta','alerta_furtividade')
$premissas = @('encontrou_lobo','lobo_avancou','encontrou_lobo_ferido','coruja_notou','coruja_avisou','cao_ofereceu_guia','notou_armadilha','acionou_armadilha','viu_jogador','viu_pegadas_alheias','reconhece_calcado','usou_esconderijo','sumiu_na_mata','recebeu_frase','enviou_frase','tem_item','visitou_outra_base')
$premissasObrigatorias = @{
  bento_04=@('lobo_avancou'); bento_05=@('viu_pegadas_alheias'); bento_11=@('enviou_frase'); bento_13=@('coruja_notou')
  iara_04=@('encontrou_lobo_ferido'); iara_05=@('coruja_avisou'); iara_06=@('cao_ofereceu_guia'); iara_07=@('notou_armadilha'); iara_08=@('recebeu_frase'); iara_12=@('encontrou_lobo'); iara_13=@('viu_jogador'); iara_14=@('recebeu_frase')
  anselmo_06=@('enviou_frase'); anselmo_09=@('tem_item','visitou_outra_base'); anselmo_11=@('visitou_outra_base'); anselmo_12=@('marca:negou_mentira'); anselmo_13=@('notou_armadilha')
  marta_05=@('visitou_outra_base','viu_pegadas_alheias'); marta_06=@('viu_pegadas_alheias'); marta_08=@('viu_jogador'); marta_11=@('viu_jogador'); marta_14=@('notou_armadilha')
  quincas_06=@('tem_item'); quincas_09=@('tem_item'); quincas_11=@('tem_item'); quincas_14=@('tem_item')
}
$retiradas = @{
  bento=@('bento_11'); iara=@('iara_12'); anselmo=@('anselmo_09','anselmo_11'); marta=@('marta_06'); quincas=@('quincas_06','quincas_09','quincas_11','quincas_14')
}
$atributos = @('forca','inteligencia','carisma','furtividade','resistencia')
$erros = [System.Collections.Generic.List[string]]::new()
$docs = @{}
$marcasPorGuardiao = @{}

function Falha([string]$texto) { $erros.Add($texto) }
function Inteiro-Faixa($valor,[int]$min,[int]$max,[string]$local) {
  if ($null -eq $valor -or $valor -isnot [ValueType] -or [double]$valor % 1 -ne 0 -or $valor -lt $min -or $valor -gt $max) { Falha "Inteiro fora da faixa $min..$max em $local" }
}
function Intencao($valor,[string]$local) { if ($null -ne $valor -and $valor -notin @('boa','ma')) { Falha "Intenção inválida em $local" } }
function Marcas($lista,[string]$local) { foreach ($marca in @($lista)) { if ($marca -isnot [string] -or $marca -notmatch '^[a-z][a-z0-9_]*$') { Falha "Marca inválida em $local" } } }

# Primeira passagem: JSON, documentos e origem das marcas.
foreach ($g in $guardioes) {
  $path = Join-Path $base "$g.json"
  try { $doc = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json } catch { Falha "JSON inválido em ${g}.json: $($_.Exception.Message)"; continue }
  $docs[$g] = $doc
  $marcasPorGuardiao[$g] = @($doc.entradas.respostas.registra | Where-Object { $null -ne $_ } | ForEach-Object { $_ } | Sort-Object -Unique)
}

$idsGlobais = @{}
foreach ($g in $guardioes) {
  if (-not $docs.ContainsKey($g)) { continue }
  $doc = $docs[$g]
  if ($doc.guardiao -ne $g) { Falha "Campo guardiao incorreto em $g.json" }
  if ($doc.versao_formato -ne 3) { Falha "versao_formato deve ser 3 em $g.json" }
  foreach ($tom in @('firme','gentil','evasivo')) { Inteiro-Faixa $doc.modificadores_tom.$tom -2 2 "$g/modificadores_tom/$tom" }

  $reputacoes = @($doc.reputacao.psobject.Properties)
  if ($reputacoes.Count -lt 3) { Falha "$g precisa de ao menos 3 marcas de reputação" }
  $externas = 0
  foreach ($r in $reputacoes) {
    Inteiro-Faixa $r.Value -2 2 "$g/reputacao/$($r.Name)"
    $donos = @($guardioes | Where-Object { $_ -ne $g -and $r.Name -in $marcasPorGuardiao[$_] })
    if ($donos.Count) { $externas++ }
  }
  if ($externas -lt 3) { Falha "$g reage a menos de 3 marcas de outros guardiões" }

  $entradas = @($doc.entradas)
  if ($entradas.Count -ne 15) { Falha "$g deve ter 15 entradas" }
  if (@($entradas | Where-Object tipo -eq 'narracao').Count -ne 1) { Falha "$g deve ter 1 narração" }
  if (@($entradas | Where-Object tipo -eq 'fala').Count -ne 2) { Falha "$g deve ter 2 falas" }
  $perguntas = @($entradas | Where-Object tipo -eq 'pergunta')
  if ($perguntas.Count -ne 12) { Falha "$g deve ter 12 perguntas usáveis no MVP" }
  foreach ($n in 1..15) { $id = '{0}_{1:D2}' -f $g,$n; if ($id -notin @($entradas.id)) { Falha "ID ausente: $id" } }

  $naoObvias=0; $extras=0; $extrasNoTopo=0
  foreach ($e in $entradas) {
    $local=$e.id
    if ($idsGlobais.ContainsKey($e.id)) { Falha "ID duplicado: $local" } else { $idsGlobais[$e.id]=$true }
    if ($e.tipo -notin @('narracao','fala','pergunta')) { Falha "Tipo inválido em $local" }
    if ([string]::IsNullOrWhiteSpace($e.texto)) { Falha "Texto vazio em $local" }
    if ($e.tipo -ne 'pergunta') { if ($null -ne $e.respostas) { Falha "$local não pode ter respostas" }; continue }
    if ($e.verificavel -isnot [bool]) { Falha "verificavel não é booleano em $local" }
    if (@($e.respostas).Count -ne 3) { Falha "$local deve ter 3 respostas" }
    $afins=@()
    foreach ($r in @($e.respostas)) {
      if ([string]::IsNullOrWhiteSpace($r.texto)) { Falha "Resposta vazia em $local" }
      Inteiro-Faixa $r.afinidade -4 4 "$local/resposta"; Intencao $r.intencao "$local/resposta"; $afins += [int]$r.afinidade
      if ($null -ne $r.registra) { Marcas $r.registra "$local/registra" }
      if ($null -ne $r.contradiz) { Marcas $r.contradiz "$local/contradiz"; if ($null -eq $e.contradicao) { Falha "$local usa contradiz sem contradicao" } }
      if ($null -ne $r.tom) { foreach ($p in $r.tom.psobject.Properties) { if ($p.Name -notin @('firme','gentil','evasivo')) { Falha "Tom desconhecido em $local" }; Inteiro-Faixa $p.Value -2 2 "$local/tom/$($p.Name)" } }
    }
    $ord=@($afins|Sort-Object -Descending); if (($ord[0]-$ord[1]) -le 2) { $naoObvias++ }
    if ($e.verificavel) {
      if ([string]::IsNullOrWhiteSpace($e.verificacao)) { Falha "Falta verificacao em $local" }
      if ($null -eq $e.mentira) { Falha "Falta mentira em $local" } else { Inteiro-Faixa $e.mentira.afinidade -4 4 "$local/mentira"; Intencao $e.mentira.intencao "$local/mentira"; if ([int]$e.mentira.afinidade -ge ($afins|Measure-Object -Minimum).Minimum) { Falha "Mentira não é a pior afinidade em $local" } }
    } elseif ($null -ne $e.mentira) { Falha "Pergunta não verificável contém mentira em $local" }
    foreach ($req in @($e.requer)) { if ($null -ne $req -and $req -notin $requerMvp) { Falha "Mecânica fora do MVP '$req' em $local" } }
    foreach ($pre in @($e.premissa)) { if ($null -ne $pre -and $pre -notin $premissas -and $pre -notmatch '^marca:[a-z][a-z0-9_]*$') { Falha "Premissa inválida '$pre' em $local" } }
    if ($premissasObrigatorias.ContainsKey($local)) { foreach ($pre in $premissasObrigatorias[$local]) { if ($pre -notin @($e.premissa)) { Falha "Premissa obrigatória '$pre' ausente em $local" } } }
    if ($null -ne $e.contradicao) { Inteiro-Faixa $e.contradicao.afinidade -4 4 "$local/contradicao" }
    if ($null -ne $e.opcao_extra) { $extras++; if ($e.opcao_extra.atributo -notin $atributos) { Falha "Atributo inválido em $local" }; Inteiro-Faixa $e.opcao_extra.minimo 1 5 "$local/opcao_extra/minimo"; Inteiro-Faixa $e.opcao_extra.afinidade -4 4 "$local/opcao_extra/afinidade"; if ([int]$e.opcao_extra.afinidade -ge ($afins|Measure-Object -Maximum).Maximum) { $extrasNoTopo++ } }
    if ($null -ne $e.silencio) { Inteiro-Faixa $e.silencio.afinidade -4 4 "$local/silencio" }
  }
  if ($naoObvias -lt 8) { Falha "$g tem só $naoObvias perguntas sem resposta óbvia; mínimo 8" }
  if ($extrasNoTopo -gt [math]::Floor($extras/2)) { Falha "$g tem opções extras fortes demais: $extrasNoTopo de $extras" }
}

# Regras semânticas explicitamente mensuráveis da revisão v3.
foreach ($id in @('bento_05','marta_05','marta_06')) {
  $g=$id.Split('_')[0]; $e=$docs[$g].entradas|Where-Object id -eq $id
  if ($e.verificacao -notmatch 'calçado' -or $e.verificacao -notmatch 'viu') { Falha "$id não explica a regra de identidade por calçado e visão" }
}
$i10=$docs.iara.entradas|Where-Object id -eq 'iara_10'; $melhor=($i10.respostas.afinidade|Measure-Object -Maximum).Maximum; $nenhuma=$i10.respostas|Where-Object texto -match '^Não acionei'; if ($nenhuma.afinidade -lt $melhor) { Falha 'iara_10 pune quem honestamente não acionou armadilha' }
if (@($docs.marta.entradas|Where-Object tipo -eq pergunta|Where-Object {$null-ne$_.silencio -and $_.silencio.afinidade -gt 0}).Count -lt 7) { Falha 'Marta deve premiar silêncio na maioria das perguntas' }

# Arquivo das perguntas preservadas fora do MVP.
foreach ($g in $guardioes) {
  $path=Join-Path $fora "$g.json"
  try { $doc=Get-Content -Raw -LiteralPath $path|ConvertFrom-Json } catch { Falha "JSON inválido em fora_do_mvp/${g}.json"; continue }
  if ($doc.guardiao -ne $g -or $doc.versao_formato -ne 3 -or $doc.status -ne 'fora_do_mvp') { Falha "Cabeçalho inválido em fora_do_mvp/${g}.json" }
  $ids=@($doc.entradas.id|Sort-Object); $esperados=@($retiradas[$g]|Sort-Object)
  if (($ids -join ',') -ne ($esperados -join ',')) { Falha "Perguntas incorretas em fora_do_mvp/${g}.json" }
  foreach ($e in @($doc.entradas)) { if (-not @($e.requer|Where-Object {$_ -in $requerFora}).Count) { Falha "$($e.id) arquivada sem mecânica fora do MVP" } }
}

if ($idsGlobais.Count -ne 75) { Falha "Total principal deveria ser 75 IDs; encontrado $($idsGlobais.Count)" }
if ($erros.Count) { $erros|ForEach-Object { Write-Error $_ }; exit 1 }
Write-Output 'VALIDO V3: 5 guardiões, 60 perguntas no MVP, 9 arquivadas e regras v2/v3 aprovadas.'
