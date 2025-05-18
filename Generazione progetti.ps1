param (
    [Parameter(Mandatory=$true)]
    [string]$SolutionName,
    [Parameter(Mandatory=$true)]
    [array]$Projects,
    [hashtable]$Dependencies = @{},
    [hashtable]$folders = @{}
)
Clear-Host

# Ottieni il percorso della cartella in cui si trova lo script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Vai nella cartella dello script
Set-Location $scriptPath

$solutionFolder = $scriptPath

# Crea la cartella della solution
#$solutionFolder = Join-Path $scriptPath $SolutionName
#if (-not (Test-Path $solutionFolder)) {
#    New-Item -ItemType Directory -Path $solutionFolder | Out-Null
#}

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

    Write-Information "Generazione delle dipendenze per il progetto $projName"

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

Write-Host "Inizio rimozione di Class1.cs e dei nodi Compile nei file .csproj"
# Cerca tutti i file .csproj nella directory corrente e sottocartelle
Get-ChildItem -Path . -Filter *.csproj -Recurse | ForEach-Object {
    $csprojPath = $_.FullName
    [xml]$xml = Get-Content $csprojPath

    # Trova tutti i nodi Compile che includono o rimuovono Class1.cs
    $compileNodes = $xml.Project.ItemGroup.Compile | Where-Object {
        $_.Include -like '*Class1.cs' -or $_.Remove -like '*Class1.cs'
    }

    # Rimuovi i nodi trovati
    foreach ($node in $compileNodes) {
        $parent = $node.ParentNode
        $parent.RemoveChild($node) | Out-Null
    }

    # Salva il file aggiornato
    $xml.Save($csprojPath)
    Write-Host "Aggiornato: $csprojPath"
}

Get-ChildItem -Path . -Filter Class1.cs -Recurse -File | Remove-Item -Force -Verbose
Write-Host "Rimozione di Class1.cs completata"

Set-Location $solutionFolder

foreach ($project in $folders.Keys) {

    $projPath = ($Projects | Where-Object { $_.Name -eq $project }).Path
    $csprojPath = Join-Path $solutionFolder $projPath $project "$project.csproj"

    foreach ($folder in $folders[$project]) {
        $fullPath = Join-Path $projPath $project $folder
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "Cartella creata: $fullPath"
    }

         # Aggiorna il file .csproj
        
        if (Test-Path $csprojPath) {
           Write-Host "Aggiornamento del file .csproj: $csprojPath"
            Set-Variable -Name xml -Value ([xml](Get-Content $csprojPath -Raw)) -Force
            $itemGroup = $xml.CreateElement("ItemGroup", $xml.Project.NamespaceURI)
            
            foreach ($folder in $folders[$project]) {
                $xml.Project.AppendChild($itemGroup) | Out-Null
                $noneNode = $xml.CreateElement("Folder", $xml.Project.NamespaceURI)
                $noneNode.SetAttribute("Include", $folder)
                $itemGroup.AppendChild($noneNode) | Out-Null
                
            }
            $xml.Save($csprojPath)
            Write-Host "Aggiornato: $csprojPath"
        } else {
            Write-Warning "File csproj non trovato: $csprojPath"
        }
 
}