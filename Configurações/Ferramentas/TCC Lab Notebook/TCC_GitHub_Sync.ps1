#requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$NoBrowser,
    [switch]$TestOfflineOnce
)

$ErrorActionPreference = 'Stop'
$HelperVersion = '1.1.0'
$RepositoryRoot = 'C:\Users\muril\OneDrive\Área de Trabalho\01 - Faculdade e Estudos\TCC'
$NotebookPath = Join-Path $RepositoryRoot 'Lab Notebook - HTML\TCC_Lab_Notebook_v51.html'
$ExpectedRemoteUrl = 'https://github.com/bmuoli/TCC.git'
$ExpectedGitDir = 'C:\Users\muril\TCC_Git_Metadata\repo.git'
$GitExe = 'C:\Program Files\Git\cmd\git.exe'
$ListenAddress = [System.Net.IPAddress]::Loopback
$ListenPort = 8765
$LabRoot = [System.IO.Path]::GetFullPath((Join-Path $RepositoryRoot 'Lab Notebook - HTML')).TrimEnd('\')
$script:SyncInProgress = $false
$script:OfflineTestPending = [bool]$TestOfflineOnce

function Invoke-Git {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $previousErrorPreference = $ErrorActionPreference
    $gitEnvironmentNames = @(
        'GIT_DIR',
        'GIT_WORK_TREE',
        'GIT_INDEX_FILE',
        'GIT_COMMON_DIR',
        'GIT_OBJECT_DIRECTORY',
        'GIT_ALTERNATE_OBJECT_DIRECTORIES'
    )
    $savedGitEnvironment = @{}
    foreach ($name in $gitEnvironmentNames) {
        $savedGitEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, $null, 'Process')
    }
    $ErrorActionPreference = 'Continue'
    try {
        $lines = & $GitExe -C $RepositoryRoot @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorPreference
        foreach ($name in $gitEnvironmentNames) {
            [Environment]::SetEnvironmentVariable($name, $savedGitEnvironment[$name], 'Process')
        }
    }
    [pscustomobject]@{
        ExitCode = $exitCode
        Output = (($lines | ForEach-Object { $_.ToString() }) -join "`n").Trim()
    }
}

function Assert-Repository {
    if (-not (Test-Path -LiteralPath $RepositoryRoot -PathType Container)) {
        throw 'A pasta autorizada do TCC não foi encontrada.'
    }
    if (-not (Test-Path -LiteralPath $GitExe -PathType Leaf)) {
        throw 'Git não foi encontrado no caminho configurado.'
    }
    $inside = Invoke-Git @('rev-parse', '--is-inside-work-tree')
    $prefix = Invoke-Git @('rev-parse', '--show-prefix')
    $gitDir = Invoke-Git @('rev-parse', '--absolute-git-dir')
    if ($inside.ExitCode -ne 0 -or $inside.Output -ne 'true' -or
        $prefix.ExitCode -ne 0 -or $prefix.Output -ne '' -or
        $gitDir.ExitCode -ne 0) {
        throw 'A pasta autorizada não é a raiz de um repositório Git válido; sincronização bloqueada.'
    }
    $expectedMetadata = [System.IO.Path]::GetFullPath($ExpectedGitDir).TrimEnd('\')
    $actualMetadata = [System.IO.Path]::GetFullPath(($gitDir.Output -replace '/', '\')).TrimEnd('\')
    if (-not [string]::Equals($actualMetadata, $expectedMetadata, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Os metadados Git não correspondem ao repositório autorizado; sincronização bloqueada.'
    }
    $branch = Invoke-Git @('branch', '--show-current')
    if ($branch.ExitCode -ne 0 -or $branch.Output -ne 'main') {
        throw 'A sincronização exige a branch main; nenhuma alteração foi enviada.'
    }
}

function Assert-NoConflict {
    $unmerged = Invoke-Git @('diff', '--name-only', '--diff-filter=U')
    if ($unmerged.ExitCode -ne 0) { throw 'Não foi possível verificar conflitos locais.' }
    if ($unmerged.Output) { throw "Há arquivos em conflito: $($unmerged.Output). Resolva-os antes de sincronizar." }
    foreach ($name in @('MERGE_HEAD', 'REBASE_HEAD', 'CHERRY_PICK_HEAD')) {
        $gitPath = Invoke-Git @('rev-parse', '--git-path', $name)
        if ($gitPath.ExitCode -eq 0 -and (Test-Path -LiteralPath $gitPath.Output)) {
            throw "Existe uma operação Git incompleta ($name). Conclua ou cancele-a manualmente antes de sincronizar."
        }
    }
}

function Get-LocalStatus {
    Assert-Repository
    Assert-NoConflict
    $status = Invoke-Git @('status', '--porcelain=v1', '--untracked-files=all')
    if ($status.ExitCode -ne 0) { throw 'Não foi possível ler o estado local do Git.' }
    $count = if ($status.Output) { @($status.Output -split "`n").Count } else { 0 }
    [pscustomobject]@{
        pending = ($count -gt 0)
        count = $count
        message = if ($count -gt 0) { "$count alteração(ões) local(is)" } else { 'sem alterações locais' }
        helperVersion = $HelperVersion
    }
}

function Invoke-SafeSync {
    if ($script:SyncInProgress) { throw 'Já existe uma sincronização em andamento.' }
    $script:SyncInProgress = $true
    try {
        Assert-Repository
        Assert-NoConflict

        $preStaged = Invoke-Git @('diff', '--cached', '--name-only')
        if ($preStaged.ExitCode -ne 0) { throw 'Não foi possível verificar o índice do Git.' }
        if ($preStaged.Output) {
            throw 'Há arquivos já preparados no índice por outro programa. Nenhum commit foi feito; revise-os no GitHub Desktop e tente novamente.'
        }

        $remote = Invoke-Git @('remote', 'get-url', 'origin')
        if ($remote.ExitCode -ne 0 -or -not $remote.Output) { throw 'O remoto origin ainda não está configurado.' }
        if ($ExpectedRemoteUrl -eq '__EXPECTED_REMOTE_URL__') { throw 'O auxiliar ainda aguarda a URL final do repositório privado.' }
        if ($remote.Output.TrimEnd('/') -ne $ExpectedRemoteUrl.TrimEnd('/')) {
            throw 'A URL do remoto não corresponde ao repositório autorizado; sincronização bloqueada.'
        }

        if ($script:OfflineTestPending) {
            $script:OfflineTestPending = $false
            throw 'Erro de conexão simulado: os dados locais foram preservados e nenhum commit ou push foi executado.'
        }

        $fetch = Invoke-Git @('fetch', '--prune', 'origin', 'main')
        if ($fetch.ExitCode -ne 0) {
            throw "Não foi possível consultar o GitHub. Os dados continuam locais e nada foi commitado: $($fetch.Output)"
        }

        $remoteRef = Invoke-Git @('show-ref', '--verify', '--quiet', 'refs/remotes/origin/main')
        if ($remoteRef.ExitCode -ne 0) { throw 'A branch origin/main não foi encontrada no remoto.' }

        $relation = Invoke-Git @('rev-list', '--left-right', '--count', 'HEAD...origin/main')
        if ($relation.ExitCode -ne 0) { throw 'Não foi possível comparar a versão local com o remoto.' }
        $parts = @($relation.Output -split '\s+' | Where-Object { $_ -ne '' })
        if ($parts.Count -lt 2) { throw 'Resposta inesperada ao comparar o histórico local e remoto.' }
        $ahead = [int]$parts[0]
        $behind = [int]$parts[1]
        if ($behind -gt 0) {
            throw "O GitHub possui $behind commit(s) que não estão neste computador. Nenhum commit/push foi feito; revise e integre o remoto primeiro."
        }

        $before = Get-LocalStatus
        if (-not $before.pending) {
            if ($ahead -gt 0) {
                $pushExisting = Invoke-Git @('push', 'origin', 'main')
                if ($pushExisting.ExitCode -ne 0) { throw "Há commit(s) local(is), mas o push falhou sem force: $($pushExisting.Output)" }
                return [pscustomobject]@{ message = 'commits locais enviados; remoto confirmado'; commit = (Invoke-Git @('rev-parse', '--short', 'HEAD')).Output }
            }
            return [pscustomobject]@{ message = 'nenhuma alteração nova; remoto já estava sincronizado'; commit = (Invoke-Git @('rev-parse', '--short', 'HEAD')).Output }
        }

        $add = Invoke-Git @('add', '--all')
        if ($add.ExitCode -ne 0) { throw "Falha ao preparar os arquivos para commit: $($add.Output)" }
        $ignoredInIndex = Invoke-Git @('ls-files', '-ci', '--exclude-standard')
        if ($ignoredInIndex.ExitCode -ne 0) { throw 'Não foi possível validar as exclusões do repositório.' }
        if ($ignoredInIndex.Output) {
            throw 'A sincronização foi bloqueada porque há arquivos ignorados preparados no índice. Nenhum commit ou push foi feito.'
        }
        Assert-NoConflict

        $staged = Invoke-Git @('diff', '--cached', '--quiet')
        if ($staged.ExitCode -eq 0) { return [pscustomobject]@{ message = 'nenhuma alteração versionável após o checkpoint'; commit = (Invoke-Git @('rev-parse', '--short', 'HEAD')).Output } }
        if ($staged.ExitCode -ne 1) { throw 'Falha ao verificar as alterações preparadas.' }

        $message = 'Checkpoint do Lab Notebook - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')
        $commit = Invoke-Git @('commit', '-m', $message)
        if ($commit.ExitCode -ne 0) { throw "Falha ao criar o commit; nenhum push foi feito: $($commit.Output)" }
        $hash = (Invoke-Git @('rev-parse', '--short', 'HEAD')).Output

        $push = Invoke-Git @('push', 'origin', 'main')
        if ($push.ExitCode -ne 0) {
            throw "O commit local $hash foi preservado, mas o push falhou sem force. Verifique a conexão ou mudanças remotas e tente novamente: $($push.Output)"
        }
        [pscustomobject]@{ message = "checkpoint $hash enviado e confirmado no GitHub"; commit = $hash }
    }
    finally {
        $script:SyncInProgress = $false
    }
}

function ConvertTo-JsonBytes {
    param([Parameter(Mandatory)]$Value)
    $json = $Value | ConvertTo-Json -Depth 6 -Compress
    [System.Text.UTF8Encoding]::new($false).GetBytes($json)
}

function Get-TextSha256 {
    param([Parameter(Mandatory)][string]$Value)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Value)
        (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally { $sha.Dispose() }
}

function Add-RegisteredEvidencePaths {
    param($Value, [Parameter(Mandatory)][System.Collections.Generic.List[string]]$Paths)
    if ($null -eq $Value -or $Value -is [string] -or $Value -is [ValueType]) { return }
    if ($Value -is [System.Array]) {
        foreach ($item in $Value) { Add-RegisteredEvidencePaths -Value $item -Paths $Paths }
        return
    }
    foreach ($property in $Value.PSObject.Properties) {
        if ($property.Name -in @('relativePath', 'annotatedRelativePath') -and $property.Value -is [string] -and $property.Value) {
            $Paths.Add($property.Value)
        }
        elseif ($null -ne $property.Value -and $property.Value -isnot [string] -and $property.Value -isnot [ValueType]) {
            Add-RegisteredEvidencePaths -Value $property.Value -Paths $Paths
        }
    }
}

function Get-EvidenceManifest {
    $campaignPath = Join-Path $LabRoot 'campanha.json'
    if (-not (Test-Path -LiteralPath $campaignPath -PathType Leaf)) { return @{} }
    $campaign = Get-Content -LiteralPath $campaignPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $registered = [System.Collections.Generic.List[string]]::new()
    Add-RegisteredEvidencePaths -Value $campaign -Paths $registered
    $allowedExtensions = @('.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp')
    $manifest = @{}
    $allImages = $null
    foreach ($relativePath in ($registered | Select-Object -Unique)) {
        $extension = [System.IO.Path]::GetExtension($relativePath).ToLowerInvariant()
        if ($extension -notin $allowedExtensions) { continue }
        $candidate = [System.IO.Path]::GetFullPath((Join-Path $LabRoot ($relativePath -replace '/', '\')))
        $insideLab = $candidate.StartsWith($LabRoot + '\', [StringComparison]::OrdinalIgnoreCase)
        if (-not $insideLab) { continue }
        $resolved = $null
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $resolved = $candidate
        }
        else {
            if ($null -eq $allImages) {
                $allImages = @(Get-ChildItem -LiteralPath $LabRoot -Recurse -File -Force | Where-Object { $_.Extension.ToLowerInvariant() -in $allowedExtensions })
            }
            $fileName = [System.IO.Path]::GetFileName($relativePath)
            $matches = @($allImages | Where-Object { $_.Name -ceq $fileName })
            if ($matches.Count -eq 1) { $resolved = $matches[0].FullName }
        }
        if ($resolved) { $manifest[(Get-TextSha256 -Value $relativePath)] = $resolved }
    }
    $manifest
}

function Get-EvidenceContentType {
    param([Parameter(Mandatory)][string]$Path)
    switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        '.png'  { 'image/png' }
        '.jpg'  { 'image/jpeg' }
        '.jpeg' { 'image/jpeg' }
        '.webp' { 'image/webp' }
        '.gif'  { 'image/gif' }
        '.bmp'  { 'image/bmp' }
        default { 'application/octet-stream' }
    }
}

function Send-HttpResponse {
    param(
        [Parameter(Mandatory)][System.Net.Sockets.NetworkStream]$Stream,
        [Parameter(Mandatory)][int]$StatusCode,
        [Parameter(Mandatory)][string]$Reason,
        [Parameter(Mandatory)][byte[]]$Body,
        [Parameter(Mandatory)][string]$ContentType
    )
    $header = "HTTP/1.1 $StatusCode $Reason`r`nContent-Type: $ContentType`r`nContent-Length: $($Body.Length)`r`nCache-Control: no-store`r`nX-Content-Type-Options: nosniff`r`nConnection: close`r`n`r`n"
    $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
    $Stream.Write($headerBytes, 0, $headerBytes.Length)
    if ($Body.Length -gt 0) { $Stream.Write($Body, 0, $Body.Length) }
    $Stream.Flush()
}

function Send-Json {
    param([System.Net.Sockets.NetworkStream]$Stream, [int]$StatusCode, $Value)
    $reason = if ($StatusCode -ge 200 -and $StatusCode -lt 300) { 'OK' } elseif ($StatusCode -eq 400) { 'Bad Request' } elseif ($StatusCode -eq 403) { 'Forbidden' } elseif ($StatusCode -eq 404) { 'Not Found' } elseif ($StatusCode -eq 409) { 'Conflict' } else { 'Service Unavailable' }
    Send-HttpResponse -Stream $Stream -StatusCode $StatusCode -Reason $reason -Body (ConvertTo-JsonBytes $Value) -ContentType 'application/json; charset=utf-8'
}

if (-not (Test-Path -LiteralPath $NotebookPath -PathType Leaf)) { throw "Lab Notebook v51 não encontrado em $NotebookPath" }
Assert-Repository

$listener = [System.Net.Sockets.TcpListener]::new($ListenAddress, $ListenPort)
$listener.Start()
Write-Host "TCC GitHub Sync $HelperVersion"
Write-Host "Repositório autorizado: $RepositoryRoot"
Write-Host "Lab Notebook: http://127.0.0.1:$ListenPort/"
Write-Host 'Mantenha esta janela aberta enquanto usar o botão de sincronização. Pressione Ctrl+C para encerrar.'

if (-not $NoBrowser) { Start-Process "http://127.0.0.1:$ListenPort/" }

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $remoteAddress = $client.Client.RemoteEndPoint.Address
            if (-not [System.Net.IPAddress]::IsLoopback($remoteAddress)) { $client.Close(); continue }
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 4096, $true)
            $requestLine = $reader.ReadLine()
            if (-not $requestLine) { continue }
            $requestParts = $requestLine -split ' '
            if ($requestParts.Count -lt 2) { Send-Json $stream 400 @{ message = 'Requisição inválida.' }; continue }
            $method = $requestParts[0].ToUpperInvariant()
            $requestTarget = $requestParts[1]
            $path = ($requestTarget -split '\?')[0]
            $headers = @{}
            while ($true) {
                $line = $reader.ReadLine()
                if ([string]::IsNullOrEmpty($line)) { break }
                $separator = $line.IndexOf(':')
                if ($separator -gt 0) { $headers[$line.Substring(0, $separator).Trim().ToLowerInvariant()] = $line.Substring($separator + 1).Trim() }
            }

            if ($path -eq '/' -and $method -eq 'GET') {
                $bytes = [System.IO.File]::ReadAllBytes($NotebookPath)
                Send-HttpResponse -Stream $stream -StatusCode 200 -Reason 'OK' -Body $bytes -ContentType 'text/html; charset=utf-8'
                continue
            }
            if ($path -eq '/favicon.ico' -and $method -eq 'GET') {
                Send-HttpResponse -Stream $stream -StatusCode 204 -Reason 'No Content' -Body ([byte[]]@()) -ContentType 'image/x-icon'
                continue
            }
            if (-not $headers.ContainsKey('x-tcc-sync') -or $headers['x-tcc-sync'] -ne '1') {
                Send-Json $stream 403 @{ message = 'Requisição recusada pelo auxiliar local.' }
                continue
            }
            if ($path -eq '/api/status' -and $method -eq 'GET') {
                try { Send-Json $stream 200 (Get-LocalStatus) } catch { Send-Json $stream 503 @{ message = $_.Exception.Message; pending = $true; helperVersion = $HelperVersion } }
                continue
            }
            if ($path -eq '/api/evidence' -and $method -eq 'GET') {
                $idMatch = [regex]::Match($requestTarget, '(?:\?|&)id=([0-9a-fA-F]{64})(?:&|$)')
                if (-not $idMatch.Success) { Send-Json $stream 400 @{ message = 'Identificador de evidência inválido.' }; continue }
                try {
                    $manifest = Get-EvidenceManifest
                    $id = $idMatch.Groups[1].Value.ToLowerInvariant()
                    if (-not $manifest.ContainsKey($id)) { Send-Json $stream 404 @{ message = 'Evidência não autorizada ou não encontrada.' }; continue }
                    $assetPath = $manifest[$id]
                    $assetBytes = [System.IO.File]::ReadAllBytes($assetPath)
                    Send-HttpResponse -Stream $stream -StatusCode 200 -Reason 'OK' -Body $assetBytes -ContentType (Get-EvidenceContentType -Path $assetPath)
                }
                catch { Send-Json $stream 503 @{ message = ('Não foi possível ler a evidência: ' + $_.Exception.Message) } }
                continue
            }
            if ($path -eq '/api/sync' -and $method -eq 'POST') {
                try { Send-Json $stream 200 (Invoke-SafeSync) } catch { Send-Json $stream 409 @{ message = $_.Exception.Message; helperVersion = $HelperVersion } }
                continue
            }
            Send-Json $stream 404 @{ message = 'Endpoint não permitido.' }
        }
        catch {
            try { if ($stream) { Send-Json $stream 503 @{ message = ('Erro local: ' + $_.Exception.Message) } } } catch {}
        }
        finally {
            if ($reader) { $reader.Dispose(); $reader = $null }
            if ($stream) { $stream.Dispose(); $stream = $null }
            $client.Dispose()
        }
    }
}
finally {
    $listener.Stop()
}
