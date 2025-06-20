Set-Location "E:\Education\Saxion\Internship\Projects"

function Measure-PeakMemoryUsage {
    param (
        [string]$exePath,
        [string[]]$arguments
    )

    Write-Host "[DEBUG] memory Args received:"
    foreach ($a in $arguments) {
        Write-Host "`t'$a'"  # quotes help spot empty/malformed strings
    }
    Write-Host "`n[MEM] Running: $exePath $($argumentss -join ' ')"

    if ($marguments.Count -gt 0) {
        $proc = Start-Process -FilePath $exePath -ArgumentList @($marguments[0], $marguments[1]) -PassThru

    } else {
        $proc = Start-Process -FilePath $exePath -PassThru
    }
    Start-Sleep -Milliseconds 200

    $maxMemory = 0
    while (-not $proc.HasExited) {
        try {
            $proc.Refresh()
            $mem = $proc.WorkingSet64 / 1MB
            if ($mem -gt $maxMemory) {
                $maxMemory = $mem
            }
        } catch {}
        Start-Sleep -Milliseconds 50
    }

    return [math]::Round($maxMemory, 3)
}

function Measure-CPUTime {
    param (
        [string]$exePath,
        [string[]]$arguments
    )

    Write-Host "[DEBUG] Args received:"
    foreach ($a in $arguments) {
        Write-Host "`t'$a'"  # quotes help spot empty/malformed strings
    }
    Write-Host "`n[CPU] Running (timed): $exePath $($arguments -join ' ')"

    $duration = Measure-Command {
        & $exePath @($arguments[0], $arguments[1])
    }

    return [math]::Round($duration.TotalMilliseconds, 3)
}



# Tool definitions
$tools = @(
    @{
        Name = "CSVTransformer"
        Rust     = "RustProjects\target\release\csv_transform.exe"
        CSharp   = "CSharpProjects\CsvTransformer\bin\Release\net9.0\CsvTransformer.exe"
        CSharpCLI = "CSharpProjectsUseCLIRust\CsvStreamProcessor\bin\release\net9.0\CsvStreamProcessor.exe"
        CSharpDLL = "CharpProjectsUseDLLRust\CsharptCsvStreamProcessorUseRustDll\bin\Release\net9.0\CsharptCsvStreamProcessorUseRustDll.exe"
    }
    @{
        Name = "BatchProcessor"
        Rust     = "RustProjects\target\release\batch_job.exe"
        CSharp   = "CSharpProjects\BatchProcessor\bin\Release\net9.0\BatchProcessor.exe"
        CSharpCLI = "CSharpProjectsUseCLIRust\CsvBatchProcessor\bin\release\net9.0\CsvBatchProcessor.exe"
        CSharpDLL = "CharpProjectsUseDLLRust\CsharptCsvBatchProcessorUseRustDll\bin\Release\net9.0\CsharptCsvBatchProcessorUseRustDll.exe"
    },
    @{
        Name = "ParallelBatchProcessor"
        Rust     = "RustProjects\target\release\parallel_batch_job.exe"
        CSharp   = "CSharpProjects\ParallelBatchProcessor\bin\Release\net9.0\ParallelBatchProcessor.exe"
        CSharpCLI = "CSharpProjectsUseCLIRust\CsvParallelBatchProcessor\bin\release\net9.0\CsvParallelBatchProcessor.exe"
        CSharpDLL = "CharpProjectsUseDLLRust\CsharptCsvParallelBatchProcessorUseRustDll\bin\Release\net9.0\CsharptCsvParallelBatchProcessorUseRustDll.exe"
    }
)

# Input files
$inputs = @("small_input.csv", "large_input.csv", "huge_input.csv")

# Result collection
$results = @()

foreach ($tool in $tools) {
 
    foreach ($input in $inputs) {
        $suffix = ($input -replace "_input.csv", "")
        $inputPath = Join-Path $PWD "results\$input"
        $outputRustPath = Join-Path $PWD ("results\rust_{0}_output_{1}.csv" -f $tool.Name, $suffix)
        $outputCSharpPath = Join-Path $PWD ("results\csharp_{0}_output_{1}.csv" -f $tool.Name, $suffix)
                
        Write-Host "INPUT: $inputPath"
        Write-Host "OUTPUT (Rust): $outputRustPath"
        Write-Host "OUTPUT (C#): $outputCSharpPath"
        Write-Host "Sending args to CPU:"
        @($inputPath, $outputRustPath) | ForEach-Object { Write-Host "`t$_" }
        Write-Host "Args Type: $($args.GetType().FullName)"
        
        # RUST: Memory and CPU measured separately
        $rustExe = Join-Path $PWD $tool.Rust
        $memRust = Measure-PeakMemoryUsage -exePath $rustExe -arguments ([string[]]@($inputPath, $outputRustPath))
        $cpuRust = Measure-CPUTime -exePath $rustExe -arguments ([string[]]@($inputPath, $outputRustPath))

        $results += [PSCustomObject]@{
            Tool = $tool.Name
            InputSize = $suffix
            Language = "Rust"
            PeakMemoryMB = $memRust
            CPUTimeMS = $cpuRust
        }

        # C#: Memory and CPU measured separately
        $csharpExe = Join-Path $PWD $tool.CSharp
        $memCSharp = Measure-PeakMemoryUsage -exePath $csharpExe -arguments ([string[]]@($inputPath, $outputRustPath))
        $cpuCSharp = Measure-CPUTime -exePath $csharpExe -arguments ([string[]]@($inputPath, $outputRustPath))
        $results += [PSCustomObject]@{
            Tool = $tool.Name
            InputSize = $suffix
            Language = "C#"
            PeakMemoryMB = $memCSharp
            CPUTimeMS = $cpuCSharp
        }

        $csharpWithCLiExe = Join-Path $PWD $tool.CSharpCLI
        $memCSharpWithCLi = Measure-PeakMemoryUsage -exePath $csharpWithCLiExe -arguments ([string[]]@($inputPath, $outputRustPath)) 
        $cpuCSharpWithCLi = Measure-CPUTime -exePath $csharpWithCLiExe -arguments ([string[]]@($inputPath, $outputRustPath))
        $results += [PSCustomObject]@{
            Tool = $tool.Name
            InputSize = $suffix
            Language = "c#WithCLi"
            PeakMemoryMB = $memCSharpWithCLi
            CPUTimeMS = $cpuCSharpWithCLi
        }


        $csharpWithDLLExe = Join-Path $PWD $tool.CSharpDLL
        $memCSharpWithDLL = Measure-PeakMemoryUsage -exePath $csharpWithDLLExe -arguments ([string[]]@($inputPath, $outputRustPath)) 
        $cpuCSharpithDLL = Measure-CPUTime -exePath $csharpWithDLLExe -arguments ([string[]]@($inputPath, $outputRustPath))
        $results += [PSCustomObject]@{
            Tool = $tool.Name
            InputSize = $suffix
            Language = "C#withDLL"
            PeakMemoryMB = $memCSharpWithDLL
            CPUTimeMS = $cpuCSharpithDLL
        }
    }
}

# Output table and export
$results | Format-Table Tool, InputSize, Language, PeakMemoryMB, CPUTimeMS
$results | Export-Csv -Path "memory_cpu_benchmarks.csv" -NoTypeInformation
