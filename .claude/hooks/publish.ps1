$ErrorActionPreference = 'Stop'

try {
    $projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
    $expectedRemote = 'https://github.com/nicolaszuge/palavras-que-acolhem-site.git'

    $branch = (& git -C $projectRoot branch --show-current 2>&1).Trim()
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'main') {
        throw 'Publicação automática requer a branch main do projeto.'
    }

    $remote = (& git -C $projectRoot remote get-url origin 2>&1).Trim()
    if ($LASTEXITCODE -ne 0 -or $remote -ne $expectedRemote) {
        throw 'O remoto GitHub não corresponde ao projeto esperado.'
    }

    $htmlPath = Join-Path $projectRoot 'index.html'
    if (-not (Test-Path -LiteralPath $htmlPath)) {
        throw 'index.html não foi encontrado.'
    }
    $html = Get-Content -LiteralPath $htmlPath -Raw -Encoding UTF8
    foreach ($url in @(
        'https://pay.wiapy.com/_7l98W2MAcri',
        'https://pay.wiapy.com/NJk-2Cg_J8gl',
        'https://pay.wiapy.com/COM7fqgw0aBE'
    )) {
        if (-not $html.Contains($url)) {
            throw "Link de checkout ausente: $url"
        }
    }

    & git -C $projectRoot add -A -- index.html assets
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao preparar os arquivos do site.' }

    & git -C $projectRoot diff --cached --quiet -- index.html assets
    if ($LASTEXITCODE -eq 0) { exit 0 }
    if ($LASTEXITCODE -ne 1) { throw 'Falha ao verificar mudanças do site.' }

    & git -C $projectRoot -c user.name='Palavras que Acolhem' -c user.email='site@users.noreply.github.com' commit --only -m 'Atualiza pagina de vendas via Claude' -- index.html assets
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao registrar a atualização.' }

    & git -C $projectRoot push origin main
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao enviar ao GitHub; a versão pública não foi atualizada.' }
    exit 0
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 2
}
