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

# Ottieni il percorso della cartella in cui si trova lo script
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

$folders = @{
    "$SolutionName.Domain" = @(
        "Abstractions", 
        "Abstractions/Persistence", 
        "Abstractions/Events"
    )
    "$SolutionName.Application" = @(
        "Abstractions", 
        "Abstractions/Behaviors",
        "Abstractions/Providers", 
        "Abstractions/Services", 
        "Abstractions/Proxies",
        "Abstractions/Messages",
        "Extensions",
        "Features"
    )
    "$SolutionName.Infrastructure" = @(
        "Extensions",
        "Services",
        "Installers",
        "Providers",
        "Proxies",
        "Queues",
        "Queues/Consumers",
        "Queues/Producers",
        "Jobs"
    )
}

$arrayList = [System.Collections.ArrayList]::new()

# Configurazione Modules
$Modules -split "," | ForEach-Object {
    $projectName = $_.Trim()
    
    $infraModule = @{
        Name ="Modules.$projectName.Infrastructure"
        Path = "src/Modules/$projectName"
        Template = "classlib"
    }
    $projects += $infraModule

    $folders["Modules.$projectName.Infrastructure"] = @(
        "Extensions",
        "Services",
        "Providers",
        "Proxies",
        "Queues",
        "Queues/Consumers",
        "Queues/Producers",
        "Jobs"
    )

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

    $folders["Modules.$projectName.Domain"] = @(
            "Abstractions", 
            "Abstractions/Persistence", 
            "Abstractions/Events"
        )

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

    [void]$arrayList.Add("Modules.$projectName.Infrastructure")
}
  
 $dependencies["$SolutionName.App"] = @(
             $arrayList.ToArray()
    )

try {
    & "$PSScriptRoot\Generazione progetti.ps1" -SolutionName $SolutionName -Projects $projects -Dependencies $dependencies -Folders  $folders
} catch {
    Write-Error "Errore nell'esecuzione di Generazione progetti.ps1: $_"
}