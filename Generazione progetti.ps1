param (
    [Parameter(Mandatory=$true)]
    [string]$SolutionName,
    [Parameter(Mandatory=$true)]
    [array]$Projects,
    [hashtable]$Dependencies = @{}
)
Clear-Host

# Ottieni il percorso della cartella in cui si trova lo script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Vai nella cartella dello script
Set-Location $scriptPath

# Crea la cartella della solution
$solutionFolder = Join-Path $scriptPath $SolutionName
if (-not (Test-Path $solutionFolder)) {
    New-Item -ItemType Directory -Path $solutionFolder | Out-Null
}

Set-Location $solutionFolder

# Crea la solution
dotnet new sln --name $SolutionName

# Crea i progetti nelle rispettive cartelle e aggiungili alla solution
foreach ($proj in $Projects) {
    $projName = $proj.Name
    $projPath = $proj.Path
    $projTemplate = $proj.Template
    
    $fullProjPath = Join-Path $solutionFolder "$projPath/$projName"

    # Crea la cartella se non esiste
    if (-not (Test-Path $fullProjPath)) {
        New-Item -ItemType Directory -Path $fullProjPath -Force | Out-Null
    }

    # Crea il progetto nel percorso specificato con il template specificato
    dotnet new $projTemplate --name $projName --output $fullProjPath 

    # Aggiungi il progetto alla solution (percorso relativo)
    $csprojPath = Join-Path $projPath $projName "$projName.csproj"

    dotnet sln add $csprojPath
}

Write-Host "Solution e progetti creati nella cartella: $solutionFolder"

Write-Host "Inizio generazione delle dipendenze"

# Aggiungi i riferimenti tra progetti
foreach ($projName in $Dependencies.Keys) {

    Write-Information "Generazione delle dipendeze per il progetto $projName"

    # Recupero il percorso del progetto che è stato definito
    $referenceProjects = $Dependencies[$projName]
    $projPath = ($Projects | Where-Object { $_.Name -eq $projName }).Path
    
    $sourceCsproj = Join-Path $projPath $projName "$projName.csproj"    
    
    foreach ($refProj in $referenceProjects) {

        $refProjPath = ($Projects | Where-Object { $_.Name -eq $refProj }).Path
        $targetCsproj = Join-Path $refProjPath $refProj "$refProj.csproj"

        dotnet add $sourceCsproj reference $targetCsproj
    }
}

Set-Location $solutionFolder
Write-Host "Riferimenti tra progetti aggiunti correttamente"

