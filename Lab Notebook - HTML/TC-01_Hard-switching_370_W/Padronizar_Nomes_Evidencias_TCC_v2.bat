@echo off
setlocal EnableExtensions
chcp 65001 >nul
title TCC - Padronizar nomes de evidencias

set "REN_ROOT=%~1"
if "%REN_ROOT%"=="" set "REN_ROOT=%CD%"

echo.
echo ================================================================
echo  TCC - Padronizar nomes das evidencias
echo ================================================================
echo  Pasta alvo:
echo  %REN_ROOT%
echo.
echo  [1] PREVIA - mostra o que sera alterado, sem tocar nos arquivos
echo  [2] APLICAR - renomeia, atualiza JSONs e cria backup/log
echo  [0] Cancelar
echo.
set /p "REN_MODE=Escolha: "

if "%REN_MODE%"=="0" exit /b 0
if not "%REN_MODE%"=="1" if not "%REN_MODE%"=="2" (
  echo Opcao invalida.
  pause
  exit /b 1
)

set "TMP_PS1=%TEMP%\TCC_Rename_%RANDOM%_%RANDOM%.ps1"

REM Extrai SOMENTE o bloco PowerShell que vem depois da linha marcadora.
REM A busca e por linha exata, evitando o erro da versao anterior.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$lines=[IO.File]::ReadAllLines('%~f0'); $idx=[Array]::IndexOf($lines,'#__POWERSHELL_PAYLOAD__#'); if($idx -lt 0){exit 90}; $payload=$lines[($idx+1)..($lines.Length-1)]; [IO.File]::WriteAllLines('%TMP_PS1%',$payload,[Text.UTF8Encoding]::new($false))"
if errorlevel 1 (
  echo.
  echo ERRO: nao foi possivel extrair o bloco PowerShell.
  pause
  exit /b 90
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%TMP_PS1%"
set "RC=%ERRORLEVEL%"
del "%TMP_PS1%" >nul 2>nul

echo.
if "%RC%"=="0" (
  echo Concluido.
) else (
  echo O script terminou com erro. Codigo: %RC%
)
pause
exit /b %RC%

#__POWERSHELL_PAYLOAD__#
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($env:REN_ROOT)
$apply = ($env:REN_MODE -eq '2')

if(-not (Test-Path -LiteralPath $root -PathType Container)){
    throw "Pasta nao encontrada: $root"
}

function Is-SkippedPath([string]$path){
    return ($path -match '(?i)[\\/](Historico|_rename_backup_[^\\/]+)[\\/]')
}

function Normalize-FileName([string]$name){
    $ext  = [IO.Path]::GetExtension($name)
    $stem = [IO.Path]::GetFileNameWithoutExtension($name)
    $n = $stem

    # Remove apenas o rotulo automatico. Nao remove sufixos manuais.
    $n = $n -replace '(?i)_Forma_de_onda_', '_'
    $n = $n -replace '(?i)_Forma_de_onda$', ''

    # Capturas com mais de um sinal.
    $n = $n -replace '(?i)_Tensao_e_Corrente_VDS_IDS_V_A(?=_|\d|$)', '_Geral_VDS_IDS_'
    $n = $n -replace '(?i)_Tensao_e_Corrente_VDS_ID_V_A(?=_|\d|$)',  '_Geral_VDS_IDS_'
    $n = $n -replace '(?i)_Tensao_VDS_e_VGS_V(?=_|\d|$)',             '_Geral_VDS_VGS_'
    $n = $n -replace '(?i)_Tensao_e_Corrente_V_A(?=_|\d|$)',          '_Geral_IV_'
    $n = $n -replace '(?i)_Tensao_e_Corrente_I_V(?=_|\d|$)',          '_Geral_IV_'
    $n = $n -replace '(?i)_Corrente_e_Tensao_I_V(?=_|\d|$)',          '_Geral_IV_'

    # Nomes legados mais curtos.
    $n = $n -replace '(?i)_Corrente_I_A(?=_|\d|$)', '_Corrente_A_'
    $n = $n -replace '(?i)_Corrente_I(?=_|\d|$)',   '_Corrente_A_'
    $n = $n -replace '(?i)_Corrente_ID_A(?=_|\d|$)', '_Corrente_IDS_A_'
    $n = $n -replace '(?i)_Corrente_ID(?=_|\d|$)',   '_Corrente_IDS_A_'

    # Limpeza de separadores gerados pelas substituicoes.
    $n = $n -replace '__+', '_'
    $n = $n.Trim('_')

    return $n + $ext
}

$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$backupDir = Join-Path $root ("_rename_backup_" + $stamp)
$log = New-Object System.Collections.Generic.List[object]
$fileNameMap = @{}

function Add-Log($type,$old,$new,$status,$note=''){
    $log.Add([pscustomobject]@{
        Tipo=$type; Antigo=$old; Novo=$new; Status=$status; Observacao=$note
    })
}

Write-Host ""
Write-Host ("Modo: " + $(if($apply){'APLICAR'}else{'PREVIA'})) -ForegroundColor Cyan
Write-Host "Raiz: $root"
Write-Host ""

# ---------------------------------------------------------------
# 1) Arquivos de imagem em Evidencias
# ---------------------------------------------------------------
$extensions = @('.png','.jpg','.jpeg','.webp','.bmp','.tif','.tiff')
$files = Get-ChildItem -LiteralPath $root -Recurse -File -Force | Where-Object {
    ($extensions -contains $_.Extension.ToLowerInvariant()) -and
    (-not (Is-SkippedPath $_.FullName)) -and
    ($_.FullName -match '(?i)[\\/]Evidencias[\\/]')
}

foreach($f in $files){
    $newName = Normalize-FileName $f.Name
    if($newName -eq $f.Name){ continue }

    $dest = Join-Path $f.DirectoryName $newName
    if(Test-Path -LiteralPath $dest){
        Add-Log 'ARQUIVO' $f.FullName $dest 'IGNORADO' 'Destino ja existe'
        Write-Host "[IGNORADO] $($f.Name) -> $newName (destino ja existe)" -ForegroundColor Yellow
        continue
    }

    $fileNameMap[$f.Name] = $newName

    if($apply){
        Rename-Item -LiteralPath $f.FullName -NewName $newName
        Add-Log 'ARQUIVO' $f.FullName $dest 'OK'
        Write-Host "[ARQUIVO] $($f.Name) -> $newName" -ForegroundColor Green
    } else {
        Add-Log 'ARQUIVO' $f.FullName $dest 'PREVIA'
        Write-Host "[ARQUIVO] $($f.Name) -> $newName"
    }
}

# ---------------------------------------------------------------
# 2) Pastas antigas de sinal: Forma_de_onda\I e \V
#    Mantemos a pasta Forma_de_onda; so padronizamos o sinal.
# ---------------------------------------------------------------
$dirs = Get-ChildItem -LiteralPath $root -Recurse -Directory -Force | Where-Object {
    (-not (Is-SkippedPath $_.FullName)) -and
    ($_.Parent.Name -eq 'Forma_de_onda') -and
    ($_.Name -in @('I','V'))
} | Sort-Object { $_.FullName.Length } -Descending

foreach($d in $dirs){
    $newLeaf = if($d.Name -eq 'I'){'Corrente_A'}else{'Tensao_V'}
    $target = Join-Path $d.Parent.FullName $newLeaf

    if(-not $apply){
        Add-Log 'PASTA' $d.FullName $target 'PREVIA'
        Write-Host "[PASTA] $($d.FullName) -> $target"
        continue
    }

    if(-not (Test-Path -LiteralPath $target)){
        Rename-Item -LiteralPath $d.FullName -NewName $newLeaf
        Add-Log 'PASTA' $d.FullName $target 'OK'
        Write-Host "[PASTA] $($d.Name) -> $newLeaf" -ForegroundColor Green
    } else {
        # Mescla sem sobrescrever arquivos existentes.
        foreach($child in Get-ChildItem -LiteralPath $d.FullName -Force){
            $childDest = Join-Path $target $child.Name
            if(Test-Path -LiteralPath $childDest){
                Add-Log 'MESCLA' $child.FullName $childDest 'IGNORADO' 'Destino ja existe'
                Write-Host "[IGNORADO] $($child.Name) ja existe em $newLeaf" -ForegroundColor Yellow
            } else {
                Move-Item -LiteralPath $child.FullName -Destination $target
                Add-Log 'MESCLA' $child.FullName $childDest 'OK'
                Write-Host "[MESCLA] $($child.Name) -> $newLeaf" -ForegroundColor Green
            }
        }
        if(@(Get-ChildItem -LiteralPath $d.FullName -Force).Count -eq 0){
            Remove-Item -LiteralPath $d.FullName
        }
    }
}

# ---------------------------------------------------------------
# 3) JSONs atuais (Historico fica intacto de proposito)
# ---------------------------------------------------------------
$jsonFiles = New-Object System.Collections.Generic.List[string]
Get-ChildItem -LiteralPath $root -Recurse -File -Force | Where-Object {
    (-not (Is-SkippedPath $_.FullName)) -and ($_.Name -in @('dados.json','campanha.json'))
} | ForEach-Object { [void]$jsonFiles.Add($_.FullName) }

# Se a raiz for um TC, procura campanha.json em ate quatro pais.
$p = [IO.DirectoryInfo]$root
for($level=0; $level -lt 4 -and $null -ne $p; $level++){
    $campaign = Join-Path $p.FullName 'campanha.json'
    if((Test-Path -LiteralPath $campaign) -and (-not $jsonFiles.Contains($campaign))){
        [void]$jsonFiles.Add($campaign)
    }
    $p = $p.Parent
}

if($apply -and $jsonFiles.Count -gt 0){
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $backupDir 'json_backup') -Force | Out-Null
}

foreach($jf in $jsonFiles){
    $oldText = [IO.File]::ReadAllText($jf,[Text.Encoding]::UTF8)
    $newText = $oldText

    # Corrige as pastas antigas dentro dos caminhos JSON.
    $newText = $newText -replace '(?i)(/Forma_de_onda/)I/', '${1}Corrente_A/'
    $newText = $newText -replace '(?i)(/Forma_de_onda/)V/', '${1}Tensao_V/'

    # Corrige exatamente os basenames que foram/serao renomeados.
    foreach($oldName in $fileNameMap.Keys){
        $newName = $fileNameMap[$oldName]
        $newText = $newText.Replace($oldName,$newName)
    }

    if($newText -eq $oldText){ continue }

    if($apply){
        $safe = ($jf -replace '[:\\/]','_').Trim('_')
        Copy-Item -LiteralPath $jf -Destination (Join-Path (Join-Path $backupDir 'json_backup') $safe) -Force
        [IO.File]::WriteAllText($jf,$newText,[Text.UTF8Encoding]::new($false))
        Add-Log 'JSON' $jf $jf 'OK' 'Backup criado'
        Write-Host "[JSON] Atualizado: $jf" -ForegroundColor Green
    } else {
        Add-Log 'JSON' $jf $jf 'PREVIA'
        Write-Host "[JSON] Seria atualizado: $jf"
    }
}

# ---------------------------------------------------------------
# 4) Log e backup
# ---------------------------------------------------------------
if($apply){
    if(-not (Test-Path -LiteralPath $backupDir)){
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    $log | Export-Csv -LiteralPath (Join-Path $backupDir 'rename_log.csv') -NoTypeInformation -Encoding UTF8

    $readme = @"
Padronizacao aplicada em: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Raiz processada: $root

Regras:
- Forma_de_onda\\I -> Forma_de_onda\\Corrente_A
- Forma_de_onda\\V -> Forma_de_onda\\Tensao_V
- Remove _Forma_de_onda_ apenas do NOME do arquivo.
- Capturas com tensao + corrente podem virar Geral_...
- Sufixos manuais como Resistores_Gate e Panoramica sao preservados.
- Historico nao foi alterado.
- dados.json/campanha.json foram atualizados quando necessario.
"@
    [IO.File]::WriteAllText((Join-Path $backupDir 'LEIA-ME.txt'),$readme,[Text.UTF8Encoding]::new($false))

    Write-Host ""
    Write-Host "Backup/log: $backupDir" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Resumo:" -ForegroundColor Cyan
$log | Group-Object Tipo,Status | ForEach-Object {
    Write-Host ("  {0}: {1}" -f $_.Name,$_.Count)
}

if(-not $apply){
    Write-Host ""
    Write-Host "PREVIA concluida. Nenhum arquivo foi alterado." -ForegroundColor Yellow
    Write-Host "Se estiver correto, rode novamente e escolha [2] APLICAR."
}
