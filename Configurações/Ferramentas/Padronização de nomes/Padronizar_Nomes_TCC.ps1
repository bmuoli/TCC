param([string]$Root)

$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Join-Path $PSScriptRoot '..\..\..\Lab Notebook - HTML' }
$rootPath = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
$manifestPath = Join-Path $PSScriptRoot 'renomeacoes.csv'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw 'renomeacoes.csv nao encontrado ao lado do programa.' }
if (-not (Test-Path -LiteralPath (Join-Path $rootPath 'campanha.json') -PathType Leaf)) {
    throw "Pasta do Lab Notebook invalida ou sem campanha.json: $rootPath"
}

function Local-Path([string]$relative) {
    if ($relative -match '(^/|^[A-Za-z]:|(^|/)\.\.(/|$)|\\)') { throw "Caminho invalido no manifesto: $relative" }
    $full = [IO.Path]::GetFullPath((Join-Path $rootPath ($relative.Replace('/', [IO.Path]::DirectorySeparatorChar))))
    if (-not $full.StartsWith(($rootPath + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) {
        throw "Caminho fora da pasta do TCC: $relative"
    }
    return $full
}

$plan = @()
foreach ($row in @(Import-Csv -LiteralPath $manifestPath -Delimiter ';' -Encoding UTF8)) {
    $old = Local-Path $row.Antigo
    $intermediate = Local-Path $row.Intermediario
    $new = Local-Path $row.Novo
    if (-not $row.SHA256 -or $row.SHA256 -notmatch '^[0-9a-fA-F]{64}$') { throw "SHA256 invalido: $($row.Antigo)" }
    $candidates = @($old)
    if (-not [string]::Equals($old, $intermediate, [StringComparison]::OrdinalIgnoreCase)) { $candidates += $intermediate }
    $found = @($candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
    $source = $old
    if ($found.Count -gt 1) { $state = 'CONFLITO_ORIGENS' }
    elseif ($found.Count -eq 1) {
        $source = $found[0]
        if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ine $row.SHA256) { $state = 'CONTEUDO_ALTERADO' }
        elseif ([string]::Equals($source, $new, [StringComparison]::OrdinalIgnoreCase)) {
            if ((Get-Item -LiteralPath $source).Name -ceq [IO.Path]::GetFileName($new)) { $state = 'JA_RENOMEADO' }
            else { $state = 'RENOMEAR_CASE' }
        }
        elseif (Test-Path -LiteralPath $new) { $state = 'CONFLITO_DESTINO' }
        else { $state = 'RENOMEAR' }
    }
    elseif ((Test-Path -LiteralPath $new -PathType Leaf) -and
            ((Get-FileHash -LiteralPath $new -Algorithm SHA256).Hash -ieq $row.SHA256)) { $state = 'JA_RENOMEADO' }
    else { $state = 'AUSENTE' }
    $plan += [pscustomobject]@{ Antigo=$row.Antigo; Intermediario=$row.Intermediario; Novo=$row.Novo; SHA256=$row.SHA256; Origem=$source; Destino=$new; Estado=$state }
}

$oldKeys = @{}; $newKeys = @{}
foreach ($item in $plan) {
    $ok = $item.Antigo.ToLowerInvariant(); $nk = $item.Destino.ToLowerInvariant()
    if ($oldKeys.ContainsKey($ok) -or $newKeys.ContainsKey($nk)) { throw 'O manifesto possui caminhos repetidos.' }
    $oldKeys[$ok] = $true; $newKeys[$nk] = $true
}

Write-Host "Pasta: $rootPath"
Write-Host "Itens no manifesto: $($plan.Count)"
foreach ($item in $plan) {
    Write-Host ("[{0}] {1}  ->  {2}" -f $item.Estado, $item.Antigo, [IO.Path]::GetFileName($item.Novo))
}
$problems = @($plan | Where-Object { $_.Estado -notin @('RENOMEAR', 'RENOMEAR_CASE', 'JA_RENOMEADO') })
$toRename = @($plan | Where-Object { $_.Estado -in @('RENOMEAR', 'RENOMEAR_CASE') })
Write-Host "`nA renomear: $($toRename.Count); ja renomeados: $(@($plan | Where-Object Estado -eq 'JA_RENOMEADO').Count); problemas: $($problems.Count)."
if ($problems.Count -gt 0) {
    Write-Host 'Operacao bloqueada. Resolva os itens indicados; nenhum arquivo foi alterado.' -ForegroundColor Yellow
    exit 2
}
# Preserva a formatacao dos JSON. Os campos fileName/annotatedFileName sao
# corrigidos somente quando o caminho correspondente aponta para a imagem.
function Update-JsonText([string]$source, [array]$changes) {
    $result = $source
    foreach ($item in $changes) {
        $oldBase = [IO.Path]::GetFileName($item.Antigo)
        $newBase = [IO.Path]::GetFileName($item.Novo)
        $pattern = '("(?:fileName|annotatedFileName)"\s*:\s*")' + [regex]::Escape($oldBase) + '("[^{}]*?"(?:relativePath|annotatedRelativePath)"\s*:\s*")' + [regex]::Escape($item.Antigo) + '("[\s,}])'
        $result = [regex]::Replace($result, $pattern, {
            param($match)
            return $match.Groups[1].Value + $newBase + $match.Groups[2].Value + $item.Antigo + $match.Groups[3].Value
        })
        $result = $result.Replace($item.Antigo, $item.Novo)
    }
    return $result
}

$jsonChanges = @()
foreach ($item in $plan) {
    foreach ($alias in @($item.Antigo, $item.Intermediario)) {
        if (-not [string]::Equals($alias, $item.Novo, [StringComparison]::Ordinal) -and
            -not ($jsonChanges | Where-Object { $_.Antigo -ceq $alias -and $_.Novo -ceq $item.Novo } | Select-Object -First 1)) {
            $jsonChanges += [pscustomobject]@{ Antigo=$alias; Novo=$item.Novo }
        }
    }
}

$jsonFiles = @(Get-ChildItem -LiteralPath $rootPath -Recurse -File -Filter '*.json' | Where-Object {
    $_.Name -eq 'campanha.json' -or ($_.Name -eq 'dados.json' -and $_.FullName -notmatch '(?i)[\\/](Historico|_padronizacao_backup_[^\\/]+)[\\/]')
})
$updates = @()
foreach ($file in $jsonFiles) {
    $oldText = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
    $newText = Update-JsonText $oldText $jsonChanges
    if ($newText -ne $oldText) {
        $null = $newText | ConvertFrom-Json
        $updates += [pscustomobject]@{ Path=$file.FullName; Text=$newText }
    }
}
Write-Host "JSON atuais a atualizar: $($updates.Count)."
if ($toRename.Count -eq 0 -and $updates.Count -eq 0) {
    Write-Host 'Todos os nomes e caminhos do manifesto ja estao aplicados.' -ForegroundColor Green
    exit 0
}
Write-Host "`n[1] Apenas previa (nenhuma alteracao)"
Write-Host '[2] Aplicar, atualizar JSON e guardar copias de seguranca'
Write-Host '[0] Cancelar'
$choice = Read-Host 'Escolha'
if ($choice -ne '2') { Write-Host 'Nenhum arquivo foi alterado.'; exit 0 }

$backupRoot = Join-Path $PSScriptRoot 'Backups'
if (-not (Test-Path -LiteralPath $backupRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $backupRoot | Out-Null
}
$backup = Join-Path $backupRoot ('_padronizacao_backup_' + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
if (Test-Path -LiteralPath $backup) { throw 'Pasta de backup ja existe. Tente novamente em um segundo.' }
$moved = New-Object System.Collections.ArrayList
$savedJson = New-Object System.Collections.ArrayList
try {
    New-Item -ItemType Directory -Path $backup | Out-Null
    $jsonBackup = Join-Path $backup 'JSON_originais'
    New-Item -ItemType Directory -Path $jsonBackup | Out-Null
    foreach ($update in $updates) {
        $relative = $update.Path.Substring($rootPath.Length).TrimStart('\', '/')
        $copyPath = Join-Path $jsonBackup $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $copyPath) -Force | Out-Null
        Copy-Item -LiteralPath $update.Path -Destination $copyPath
        [void]$savedJson.Add([pscustomobject]@{ Original=$update.Path; Copy=$copyPath })
    }
    foreach ($item in $toRename) {
        if ($item.Estado -eq 'RENOMEAR_CASE') {
            $tempName = $item.Origem + '.tcc_rename_' + [guid]::NewGuid().ToString('N')
            Move-Item -LiteralPath $item.Origem -Destination $tempName
            [void]$moved.Add([pscustomobject]@{ Origem=$item.Origem; Destino=$tempName })
            Move-Item -LiteralPath $tempName -Destination $item.Destino
            [void]$moved.Add([pscustomobject]@{ Origem=$tempName; Destino=$item.Destino })
        } else {
            Move-Item -LiteralPath $item.Origem -Destination $item.Destino
            [void]$moved.Add([pscustomobject]@{ Origem=$item.Origem; Destino=$item.Destino })
        }
    }
    foreach ($update in $updates) {
        $temp = $update.Path + '.padronizacao.tmp'
        try {
            [IO.File]::WriteAllText($temp, $update.Text, [Text.UTF8Encoding]::new($false))
            Move-Item -LiteralPath $temp -Destination $update.Path -Force
        }
        finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
    }
    $toRename | Select-Object Antigo,Intermediario,Novo,SHA256 | Export-Csv -LiteralPath (Join-Path $backup 'renomeacoes_aplicadas.csv') -Delimiter ';' -Encoding UTF8 -NoTypeInformation
    [IO.File]::WriteAllText((Join-Path $backup 'LEIA-ME.txt'),
        "Imagens apenas renomeadas (sem conversao). JSON_originais guarda os JSON anteriores. Historico e demais arquivos nao foram alterados.`r`nUse renomeacoes_aplicadas.csv para conferir a lista exata.",
        [Text.UTF8Encoding]::new($false))
    Write-Host "`nConcluido: $($toRename.Count) imagens; $($updates.Count) JSON atualizados." -ForegroundColor Green
    Write-Host "Copias dos JSON e registro: $backup"
}
catch {
    Write-Host "Erro durante a aplicacao: $_" -ForegroundColor Red
    foreach ($entry in $savedJson) { Copy-Item -LiteralPath $entry.Copy -Destination $entry.Original -Force }
    for ($i=$moved.Count-1; $i -ge 0; $i--) {
        $entry = $moved[$i]
        if (Test-Path -LiteralPath $entry.Destino -PathType Leaf) { Move-Item -LiteralPath $entry.Destino -Destination $entry.Origem }
    }
    throw 'Aplicacao revertida. Verifique a mensagem acima.'
}
