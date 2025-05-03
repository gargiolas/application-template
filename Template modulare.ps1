param (
    [Parameter(Mandatory=$true)]
    [string]$SolutionName,
    [Parameter(Mandatory=$true)]
    [string]$Modules
)

$projects = @(
   
    # Configurazione Apps
    @{ Name = "$SolutionName.App"; Path = "src/Apps"; Template = "webapi" },
    
    # Configurazione Common

    @{ Name = "$SolutionName.Domain"; Path = "src/Common/Core"; Template = "classlib" },
    @{ Name = "$SolutionName.Application"; Path = "src/Common/Core"; Template = "classlib" },
    @{ Name = "$SolutionName.Infrastructure"; Path = "src/Common"; Template = "classlib" },
    @{ Name = "$SolutionName.Persistence"; Path = "src/Common"; Template = "classlib" },
    @{ Name = "$SolutionName.EndPoints"; Path = "src/Common"; Template = "classlib" },
    @{ Name = "$SolutionName.Shared"; Path = "src/Common"; Template = "classlib" }
)

ù# Ottieni il percorso della cartella in cui si trova lo script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Vai nella cartella dello script
Set-Location $scriptPath

$folderDocs = Join-Path $scriptPath "docs"
New-Item -ItemType Directory -Path $folderDocs | Out-Null
Write-Information "Cartella docs creata con successo"

$folderTests = Join-Path $scriptPath "test"
New-Item -ItemType Directory -Path $folderTests | Out-Null
Write-Information "Cartella test creata con successo"

$folderDiagrams = Join-Path $scriptPath "diagrams"
New-Item -ItemType Directory -Path $folderDiagrams | Out-Null
Write-Information "Cartella diagrams creata con successo"

$dependencies = @{
    "$SolutionName.Domain" = @("$SolutionName.Shared")
    "$SolutionName.Application" = @("$SolutionName.Domain")
    "$SolutionName.App" = @("$SolutionName.Infrastructure")
    "$SolutionName.Infrastructure" = @(
        "$SolutionName.Application",
        "$SolutionName.Persistence",
        "$SolutionName.EndPoints"
        )
    "$SolutionName.Persistence" = @("$SolutionName.Domain")  
    "$SolutionName.EndPoints" = @("$SolutionName.Application")  
}

# Configurazione Modules
$Modules -split "," | ForEach-Object {
    $projectName = $_.Trim()
    
    $infraModule = @{
        Name ="Modules.$projectName.Infrastructure"
        Path = "src/Modules/$projectName"
        Template = "classlib"
    }
    $projects += $infraModule

    $persistenceModule = @{
        Name ="Modules.$projectName.Persistence"
        Path = "src/Modules/$projectName"
        Template = "classlib"
    }
    $projects += $persistenceModule

    $endPointModule = @{
        Name ="Modules.$projectName.EndPoints"
        Path = "src/Modules/$projectName"
        Template = "classlib"
    }
    $projects += $endPointModule

    $applicationModule = @{
        Name ="Modules.$projectName.Application"
        Path = "src/Modules/$projectName/Core"
        Template = "classlib"
    }
    $projects += $applicationModule

    $domainModule = @{
        Name ="Modules.$projectName.Domain"
        Path = "src/Modules/$projectName/Core"
        Template = "classlib"
    }
    $projects += $domainModule

    $dependencies["Modules.$projectName.Domain"] = @("$SolutionName.Domain")
    $dependencies["Modules.$projectName.Application"] = @(
        "$SolutionName.Application",
        "Modules.$projectName.Domain"
        )
    $dependencies["Modules.$projectName.Infrastructure"] = @(
        "$SolutionName.Infrastructure",
         "Modules.$projectName.Application",
         "Modules.$projectName.Persistence"
         "Modules.$projectName.EndPoints"
         )
    $dependencies["Modules.$projectName.EndPoints"] = @(
        "$SolutionName.EndPoints",
         "Modules.$projectName.Application"
         )
    $dependencies["Modules.$projectName.Persistence"] = @(
            "$SolutionName.Persistence",
             "Modules.$projectName.Domain"
        )
    $dependencies["$SolutionName.Infrastructure"] = @(
             "Modules.$projectName.Infrastructure"
    )
}
  
try {
    & "$PSScriptRoot\Generazione progetti.ps1" -SolutionName $SolutionName -Projects $projects -Dependencies $dependencies
} catch {
    Write-Error "Errore nell'esecuzione di Generazione progetti.ps1: $_"
}