$ErrorActionPreference = 'Stop'
$base = Join-Path $PSScriptRoot 'guardioes'
$esperados = @('bento','iara','anselmo','marta','quincas')
$mecanicas = @('bases_visitadas','jogadores_vistos','esconderijo','aproximacao','rastros','alerta_furtividade','escuta','animais','armadilhas','inventario','trocas','frases_prontas','prendas','historico_respostas')
$atributos = @('forca','inteligencia','carisma','furtividade','resistencia')
$ids = @{}
$erros = [System.Collections.Generic.List[string]]::new()
function Inteiro-Faixa($valor,[int]$min,[int]$max,[string]$local) { if ($null -eq $valor -or $valor -isnot [ValueType] -or [double]$valor % 1 -ne 0 -or $valor -lt $min -or $valor -gt $max) { $erros.Add("Inteiro fora da faixa $min..$max em $local") } }
function Intencao-Valida($valor,[string]$local) { if ($null -ne $valor -and $valor -notin @('boa','ma')) { $erros.Add("Intenção inválida em $local") } }
function Lista-Marcas-Valida($lista,[string]$local) { foreach ($marca in @($lista)) { if ($marca -isnot [string] -or [string]::IsNullOrWhiteSpace($marca)) { $erros.Add("Marca inválida em $local") } } }

foreach ($guardiao in $esperados) {
  $arquivo = Join-Path $base "$guardiao.json"
  try { $doc = Get-Content -Raw -LiteralPath $arquivo | ConvertFrom-Json } catch { $erros.Add("JSON inválido em ${guardiao}.json: $($_.Exception.Message)"); continue }
  if ($doc.guardiao -ne $guardiao) { $erros.Add("Campo guardiao incorreto em ${guardiao}.json") }
  if ($doc.versao_formato -ne 2) { $erros.Add("versao_formato deve ser 2 em $guardiao") }
  foreach ($tom in @('firme','gentil','evasivo')) { Inteiro-Faixa $doc.modificadores_tom.$tom -2 2 "$guardiao/modificadores_tom/$tom" }
  if (@($doc.modificadores_tom.psobject.Properties.Name | Where-Object { $_ -notin @('firme','gentil','evasivo') }).Count) { $erros.Add("Tom desconhecido em $guardiao") }
  $entradas = @($doc.entradas)
  if ($entradas.Count -ne 15) { $erros.Add("$guardiao não contém 15 entradas") }
  if (@($entradas | Where-Object tipo -eq 'narracao').Count -ne 1) { $erros.Add("$guardiao deve ter 1 narração") }
  if (@($entradas | Where-Object tipo -eq 'fala').Count -ne 2) { $erros.Add("$guardiao deve ter 2 falas") }
  $perguntas = @($entradas | Where-Object tipo -eq 'pergunta')
  if ($perguntas.Count -ne 12) { $erros.Add("$guardiao deve ter 12 perguntas") }
  foreach ($n in 1..15) { $idEsperado = '{0}_{1:D2}' -f $guardiao,$n; if ($idEsperado -notin @($entradas.id)) { $erros.Add("ID ausente: $idEsperado") } }
  $naoObvias=0; $extras=0; $extrasNoTopo=0
  foreach ($item in $entradas) {
    $local=$item.id
    if ($item.id -notmatch "^${guardiao}_[0-9]{2}$") { $erros.Add("ID fora do padrão: $local") }
    if ($ids.ContainsKey($item.id)) { $erros.Add("ID duplicado: $local") } else { $ids[$item.id]=$true }
    if ($item.tipo -notin @('narracao','fala','pergunta')) { $erros.Add("Tipo inválido em $local") }
    if ([string]::IsNullOrWhiteSpace($item.texto)) { $erros.Add("Texto vazio em $local") }
    if ($item.tipo -ne 'pergunta') { if ($null -ne $item.respostas) { $erros.Add("$($item.tipo) contém respostas em $local") }; continue }
    if ($item.verificavel -isnot [bool]) { $erros.Add("verificavel não é booleano em $local") }
    if (@($item.respostas).Count -ne 3) { $erros.Add("Pergunta deve conter 3 respostas em $local") }
    $afinidades=@()
    foreach ($resposta in @($item.respostas)) {
      if ([string]::IsNullOrWhiteSpace($resposta.texto)) { $erros.Add("Resposta vazia em $local") }
      Inteiro-Faixa $resposta.afinidade -4 4 "$local/resposta"; Intencao-Valida $resposta.intencao "$local/resposta"; $afinidades += [int]$resposta.afinidade
      if ($null -ne $resposta.registra) { Lista-Marcas-Valida $resposta.registra "$local/registra" }
      if ($null -ne $resposta.contradiz) { Lista-Marcas-Valida $resposta.contradiz "$local/contradiz"; if ($null -eq $item.contradicao) { $erros.Add("Resposta usa contradiz sem contradicao em $local") } }
      if ($null -ne $resposta.tom) { foreach ($prop in $resposta.tom.psobject.Properties) { if ($prop.Name -notin @('firme','gentil','evasivo')) { $erros.Add("Tom desconhecido em $local/resposta") }; Inteiro-Faixa $prop.Value -2 2 "$local/resposta/tom/$($prop.Name)" } }
    }
    $ordenadas=@($afinidades | Sort-Object -Descending); if ($ordenadas.Count -ge 2 -and ($ordenadas[0]-$ordenadas[1]) -le 2) { $naoObvias++ }
    if ($item.verificavel) {
      if ([string]::IsNullOrWhiteSpace($item.verificacao)) { $erros.Add("Falta verificacao em $local") }
      if (@($item.requer).Count -eq 0) { $erros.Add("Pergunta verificável sem requer em $local") }
      if ($null -eq $item.mentira) { $erros.Add("Pergunta verificável sem mentira em $local") } else { Inteiro-Faixa $item.mentira.afinidade -4 4 "$local/mentira"; Intencao-Valida $item.mentira.intencao "$local/mentira"; if ([int]$item.mentira.afinidade -ge ($afinidades | Measure-Object -Minimum).Minimum) { $erros.Add("Mentira não é pior que a resposta mais baixa em $local") } }
    } elseif ($null -ne $item.mentira) { $erros.Add("Pergunta não verificável contém mentira em $local") }
    foreach ($req in @($item.requer)) { if ($null -ne $req -and $req -notin $mecanicas) { $erros.Add("Mecânica não definida '$req' em $local") } }
    if ($null -ne $item.contradicao) { Inteiro-Faixa $item.contradicao.afinidade -4 4 "$local/contradicao" }
    if ($null -ne $item.opcao_extra) { $extras++; if ($item.opcao_extra.atributo -notin $atributos) { $erros.Add("Atributo inválido em $local") }; Inteiro-Faixa $item.opcao_extra.minimo 1 5 "$local/opcao_extra/minimo"; Inteiro-Faixa $item.opcao_extra.afinidade -4 4 "$local/opcao_extra/afinidade"; if ([string]::IsNullOrWhiteSpace($item.opcao_extra.texto)) { $erros.Add("Opção extra vazia em $local") }; if ([int]$item.opcao_extra.afinidade -ge ($afinidades | Measure-Object -Maximum).Maximum) { $extrasNoTopo++ } }
    if ($null -ne $item.silencio) { Inteiro-Faixa $item.silencio.afinidade -4 4 "$local/silencio" }
  }
  if ($naoObvias -lt 8) { $erros.Add("$guardiao tem só $naoObvias perguntas sem resposta óbvia; mínimo 8") }
  if ($extrasNoTopo -gt [math]::Floor($extras/2)) { $erros.Add("$guardiao tem opções extras fortes demais: $extrasNoTopo de $extras") }
  if ($guardiao -eq 'iara' -and @($perguntas | Where-Object verificavel).Count -lt 7) { $erros.Add('Iara deve ter maioria de perguntas verificáveis') }
  if ($guardiao -eq 'marta') { $silenciosPositivos=@($perguntas | Where-Object { $null -ne $_.silencio -and $_.silencio.afinidade -gt 0 }).Count; if ($silenciosPositivos -lt 7) { $erros.Add('Marta deve ter silêncio positivo na maioria das perguntas') } }
  if ($guardiao -eq 'anselmo') { $cruzamentos=@($perguntas | Where-Object { $null -ne $_.contradicao -and @($_.respostas.contradiz).Count -gt 0 -and @($_.respostas.registra).Count -gt 0 }).Count; if ($cruzamentos -lt 4) { $erros.Add('Anselmo deve usar registra, contradiz e contradicao em pelo menos 4 perguntas') } }
}
if ($ids.Count -ne 75) { $erros.Add("Total de IDs deveria ser 75; encontrado: $($ids.Count)") }
if ($erros.Count) { $erros | ForEach-Object { Write-Error $_ }; exit 1 }
Write-Output 'VALIDO V2: 5 arquivos, 75 entradas e regras estruturais/mensuráveis aprovadas.'
