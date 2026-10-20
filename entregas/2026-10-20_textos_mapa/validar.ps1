$ErrorActionPreference = "Stop"

$erros = [System.Collections.Generic.List[string]]::new()
$raiz = $PSScriptRoot
$marcadoresPermitidos = @("direcao", "calcado", "personagem", "base", "lado", "item")

function Registrar-Erro {
    param([string]$Mensagem)
    $script:erros.Add($Mensagem)
}

function Carregar-Json {
    param([string]$Nome)
    $caminho = Join-Path $raiz $Nome
    if (-not (Test-Path -LiteralPath $caminho)) {
        Registrar-Erro "Arquivo ausente: $Nome"
        return $null
    }
    try {
        return Get-Content -Raw -LiteralPath $caminho | ConvertFrom-Json
    }
    catch {
        Registrar-Erro "JSON invalido em ${Nome}: $($_.Exception.Message)"
        return $null
    }
}

function Contar-Palavras {
    param([string]$Texto)
    if ([string]::IsNullOrWhiteSpace($Texto)) { return 0 }
    return @($Texto.Trim() -split "\s+" | Where-Object { $_ }).Count
}

function Obter-Marcadores {
    param([string]$Texto)
    return @([regex]::Matches($Texto, "\{([a-z_]+)\}") | ForEach-Object { $_.Groups[1].Value })
}

function Validar-Texto {
    param(
        [object]$Entrada,
        [int]$Limite,
        [string]$Arquivo
    )
    if ([string]::IsNullOrWhiteSpace([string]$Entrada.texto)) {
        Registrar-Erro "$Arquivo/$($Entrada.id): texto vazio"
        return
    }
    $quantidade = Contar-Palavras ([string]$Entrada.texto)
    if ($quantidade -gt $Limite) {
        Registrar-Erro "$Arquivo/$($Entrada.id): $quantidade palavras; limite $Limite"
    }
    foreach ($marcador in (Obter-Marcadores ([string]$Entrada.texto))) {
        if ($marcador -notin $marcadoresPermitidos) {
            Registrar-Erro "$Arquivo/$($Entrada.id): marcador desconhecido {$marcador}"
        }
    }
    $aberturas = ([regex]::Matches([string]$Entrada.texto, "\{")).Count
    $fechamentos = ([regex]::Matches([string]$Entrada.texto, "\}")).Count
    $reconhecidos = (Obter-Marcadores ([string]$Entrada.texto)).Count
    if ($aberturas -ne $fechamentos -or $aberturas -ne $reconhecidos) {
        Registrar-Erro "$Arquivo/$($Entrada.id): chaves ou marcadores malformados"
    }
}

$janelas = Carregar-Json "janelas.json"
$eventos = Carregar-Json "eventos_distancia.json"
$clareiras = Carregar-Json "clareiras.json"
$frases = Carregar-Json "frases_prontas.json"
$nomes = Carregar-Json "nomes.json"

$documentos = @($janelas, $eventos, $clareiras, $frases, $nomes) | Where-Object { $null -ne $_ }
foreach ($documento in $documentos) {
    if ($documento.versao_formato -ne 1) {
        Registrar-Erro "Todos os arquivos devem usar versao_formato 1"
    }
}

$todosIds = [System.Collections.Generic.List[string]]::new()

if ($null -ne $janelas) {
    $bases = @("bento", "iara", "anselmo", "marta", "quincas", "vazia")
    $situacoes = @("sozinho", "com_visitante", "sinal_mentira", "sem_ninguem")
    if (@($janelas.janelas).Count -ne 50) {
        Registrar-Erro "janelas.json: esperado 50 entradas"
    }
    foreach ($entrada in @($janelas.janelas)) {
        $todosIds.Add([string]$entrada.id)
        Validar-Texto $entrada 15 "janelas.json"
        if ($entrada.base -notin $bases) { Registrar-Erro "janelas/$($entrada.id): base invalida" }
        if ($entrada.situacao -notin $situacoes) { Registrar-Erro "janelas/$($entrada.id): situacao invalida" }
        if ($entrada.id -notmatch "^$([regex]::Escape([string]$entrada.base))_janela_\d{2}$") {
            Registrar-Erro "janelas/$($entrada.id): ID fora do padrao <base>_janela_XX"
        }
        if ($entrada.base -eq "vazia" -and $entrada.situacao -ne "sem_ninguem") {
            Registrar-Erro "janelas/$($entrada.id): base vazia aceita apenas sem_ninguem"
        }
        if ($entrada.base -ne "vazia" -and $entrada.situacao -eq "sem_ninguem") {
            Registrar-Erro "janelas/$($entrada.id): sem_ninguem e exclusivo da base vazia"
        }
    }
    foreach ($base in @("bento", "iara", "anselmo", "marta", "quincas")) {
        foreach ($situacao in @("sozinho", "com_visitante", "sinal_mentira")) {
            $n = @($janelas.janelas | Where-Object { $_.base -eq $base -and $_.situacao -eq $situacao }).Count
            if ($n -ne 3) { Registrar-Erro "janelas: esperado 3 para $base/$situacao; encontrado $n" }
        }
    }
    $vazias = @($janelas.janelas | Where-Object { $_.base -eq "vazia" -and $_.situacao -eq "sem_ninguem" }).Count
    if ($vazias -ne 5) { Registrar-Erro "janelas: esperado 5 para vazia/sem_ninguem; encontrado $vazias" }

    $sinais = @{
        bento = @("faca|lamina|lâmina", "pano|limpa|esfreg", "olhos|rosto|encar")
        iara = @("tigela", "mao|mão", "avental")
        anselmo = @("sino", "corda", "imov|imóv|parad|quiet")
        marta = @("respost|responde", "pausa|antes|mal acaba|mal termine")
        quincas = @("mao|mão|palma", "ombro", "ri|risad")
    }
    foreach ($base in $sinais.Keys) {
        foreach ($entrada in @($janelas.janelas | Where-Object { $_.base -eq $base -and $_.situacao -eq "sinal_mentira" })) {
            $textoNormalizado = ([string]$entrada.texto).ToLowerInvariant()
            foreach ($padrao in $sinais[$base]) {
                if ($textoNormalizado -notmatch $padrao) {
                    Registrar-Erro "janelas/$($entrada.id): sinal de mentira de $base incompleto ($padrao)"
                }
            }
        }
    }
}

if ($null -ne $eventos) {
    $gatilhos = @("lobo_uivou", "lobo_atacou", "coruja_piou", "cao_latiu", "armadilha_acionada", "porta_de_base", "mato_quebrado")
    if (@($eventos.eventos).Count -ne 28) { Registrar-Erro "eventos_distancia.json: esperado 28 entradas" }
    foreach ($entrada in @($eventos.eventos)) {
        $todosIds.Add([string]$entrada.id)
        Validar-Texto $entrada 12 "eventos_distancia.json"
        if ($entrada.gatilho -notin $gatilhos) { Registrar-Erro "eventos/$($entrada.id): gatilho invalido" }
        if ($entrada.id -notmatch "^$([regex]::Escape([string]$entrada.gatilho))_\d{2}$") {
            Registrar-Erro "eventos/$($entrada.id): ID fora do padrao <gatilho>_XX"
        }
        if ([string]$entrada.texto -notmatch "\{direcao\}") {
            Registrar-Erro "eventos/$($entrada.id): marcador {direcao} obrigatorio"
        }
    }
    foreach ($gatilho in $gatilhos) {
        $n = @($eventos.eventos | Where-Object { $_.gatilho -eq $gatilho }).Count
        if ($n -ne 4) { Registrar-Erro "eventos: esperado 4 para $gatilho; encontrado $n" }
    }
}

if ($null -ne $clareiras) {
    $locais = @("beco", "clareira_vazia")
    $conteudos = @("nada", "esconderijo", "item", "animal_lobo", "animal_coruja", "animal_cao", "armadilha_notada", "armadilha_acionada")
    if (@($clareiras.descobertas).Count -ne 48) { Registrar-Erro "clareiras.json: esperado 48 entradas" }
    foreach ($entrada in @($clareiras.descobertas)) {
        $todosIds.Add([string]$entrada.id)
        Validar-Texto $entrada 15 "clareiras.json"
        if ($entrada.local -notin $locais) { Registrar-Erro "clareiras/$($entrada.id): local invalido" }
        if ($entrada.conteudo -notin $conteudos) { Registrar-Erro "clareiras/$($entrada.id): conteudo invalido" }
        if ($entrada.id -notmatch "^$([regex]::Escape([string]$entrada.local))_$([regex]::Escape([string]$entrada.conteudo))_\d{2}$") {
            Registrar-Erro "clareiras/$($entrada.id): ID fora do padrao <local>_<conteudo>_XX"
        }
        $temItem = [string]$entrada.texto -match "\{item\}"
        if ($entrada.conteudo -eq "item" -and -not $temItem) { Registrar-Erro "clareiras/$($entrada.id): {item} obrigatorio" }
        if ($entrada.conteudo -ne "item" -and $temItem) { Registrar-Erro "clareiras/$($entrada.id): {item} usado fora de conteudo item" }
    }
    foreach ($local in $locais) {
        foreach ($conteudo in $conteudos) {
            $n = @($clareiras.descobertas | Where-Object { $_.local -eq $local -and $_.conteudo -eq $conteudo }).Count
            if ($n -ne 3) { Registrar-Erro "clareiras: esperado 3 para $local/$conteudo; encontrado $n" }
        }
    }
}

if ($null -ne $frases) {
    $categorias = @("panela", "rota", "perigo", "identidade", "pedido", "aviso")
    if (@($frases.frases).Count -ne 48) { Registrar-Erro "frases_prontas.json: esperado 48 entradas" }
    foreach ($entrada in @($frases.frases)) {
        $todosIds.Add([string]$entrada.id)
        Validar-Texto $entrada 10 "frases_prontas.json"
        if ($entrada.categoria -notin $categorias) { Registrar-Erro "frases/$($entrada.id): categoria invalida" }
        if ($entrada.id -notmatch "^fp_$([regex]::Escape([string]$entrada.categoria))_\d{2}$") {
            Registrar-Erro "frases/$($entrada.id): ID fora do padrao fp_<categoria>_XX"
        }
        $noTexto = @(Obter-Marcadores ([string]$entrada.texto))
        $declarados = @($entrada.marcadores | ForEach-Object { [string]$_ })
        if (($noTexto -join ",") -ne ($declarados -join ",")) {
            Registrar-Erro "frases/$($entrada.id): marcadores declarados diferem do texto ou da ordem"
        }
        if (@($declarados | Select-Object -Unique).Count -ne $declarados.Count) {
            Registrar-Erro "frases/$($entrada.id): marcador repetido na lista"
        }
    }
    foreach ($categoria in $categorias) {
        $n = @($frases.frases | Where-Object { $_.categoria -eq $categoria }).Count
        if ($n -ne 8) { Registrar-Erro "frases: esperado 8 para $categoria; encontrado $n" }
    }
}

if ($null -ne $nomes) {
    if (@($nomes.nomes).Count -ne 24) { Registrar-Erro "nomes.json: esperado 24 entradas" }
    $masculinos = @("Zé Tonico", "Bastião", "Neco", "Zé Firmino", "Nhô Lauro", "Tico", "Juvenal", "Dito", "Zeca", "Mané Lino", "Tonho", "Zé Amaro")
    $femininos = @("Dona Cotinha", "Filó", "Nhá Rita", "Zulmira", "Das Dores", "Tia Nena", "Mariquinha", "Donana", "Sinhá Rosa", "Lurdinha", "Benvinda", "Nenzinha")
    $guardioes = @("bento", "iara", "anselmo", "marta", "quincas")
    foreach ($entrada in @($nomes.nomes)) {
        $todosIds.Add([string]$entrada.id)
        if ($entrada.id -notmatch "^nome_\d{2}$") { Registrar-Erro "nomes/$($entrada.id): ID fora do padrao nome_XX" }
        if ([string]::IsNullOrWhiteSpace([string]$entrada.nome)) { Registrar-Erro "nomes/$($entrada.id): nome vazio" }
        if (([string]$entrada.nome).Length -gt 12) { Registrar-Erro "nomes/$($entrada.id): nome excede 12 caracteres" }
        if (([string]$entrada.nome).ToLowerInvariant() -in $guardioes) { Registrar-Erro "nomes/$($entrada.id): coincide com guardiao" }
    }
    $listaNomes = @($nomes.nomes | ForEach-Object { [string]$_.nome })
    if (@($listaNomes | ForEach-Object { $_.ToLowerInvariant() } | Select-Object -Unique).Count -ne 24) {
        Registrar-Erro "nomes.json: nomes repetidos"
    }
    if (($listaNomes[0..11] -join "|") -ne ($masculinos -join "|")) {
        Registrar-Erro "nomes.json: a primeira metade deve conter os 12 nomes masculinos revisados"
    }
    if (($listaNomes[12..23] -join "|") -ne ($femininos -join "|")) {
        Registrar-Erro "nomes.json: a segunda metade deve conter os 12 nomes femininos revisados"
    }
}

$idsNormalizados = @($todosIds | ForEach-Object { $_.ToLowerInvariant() })
if (@($idsNormalizados | Select-Object -Unique).Count -ne $idsNormalizados.Count) {
    Registrar-Erro "Existem IDs repetidos entre os cinco arquivos"
}

if ($erros.Count -gt 0) {
    Write-Host "INVALIDO: $($erros.Count) erro(s)" -ForegroundColor Red
    $erros | ForEach-Object { Write-Host "- $_" }
    exit 1
}

Write-Host "VALIDO: 5 arquivos, 198 entradas e formato 1." -ForegroundColor Green
Write-Host "Janelas: 50 | Eventos: 28 | Descobertas: 48 | Frases: 48 | Nomes: 24"
