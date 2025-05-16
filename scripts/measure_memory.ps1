Set-Location "E:\Education\Saxion\Internship\Projects"

function Measure-PeakMemoryUsage {
    param (
        [string]$exePath,
        [string[]]$args
    )

    Write-Host "`n[MEM] Running: $exePath $($args -join ' ')"

    if ($args.Count -gt 0) {
        $proc = Start-Process -FilePath $exePath -ArgumentList ($args -join " ") -PassThru
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
        [string[]]$args
    )

    Write-Host "`n[CPU] Running (timed): $exePath $($args -join ' ')"

    $cmdLine = "$exePath $($args -join ' ')"
    $duration = Measure-Command {
        iex "& $cmdLine"
    }

    return [math]::Round($duration.TotalMilliseconds, 3)
}



# Tool definitions
$tools = @(
    @{ Name = "CSVTransformer"; Rust = "csv_processor_rust\target\release\csv_transform.exe"; CSharp = "CsvTools\CsvTransformer\bin\Release\net9.0\CsvTransformer.exe" },
    @{ Name = "BatchProcessor"; Rust = "csv_processor_rust\target\release\batch_job.exe"; CSharp = "CsvTools\BatchProcessor\bin\Release\net9.0\BatchProcessor.exe" },
    @{ Name = "ParallelBatchProcessor"; Rust = "csv_processor_rust\target\release\parallel_batch_job.exe"; CSharp = "CsvTools\ParallelBatchProcessor\bin\Release\net9.0\ParallelBatchProcessor.exe" }
)

# Input files
$inputs = @("small_input.csv", "large_input.csv", "huge_input.csv")

# Result collection
$results = @()

foreach ($tool in $tools) {
    foreach ($input in $inputs) {
        $suffix = ($input -replace "_input.csv", "")
        $outputRust = "rust_${tool.Name}_output_${suffix}.csv"
        $outputCSharp = "csharp_${tool.Name}_output_${suffix}.csv"

        # RUST: Memory and CPU measured separately
        $rustExe = Join-Path $PWD $tool.Rust
        $memRust = Measure-PeakMemoryUsage -exePath $rustExe -args @($input, $outputRust)
        $cpuRust = Measure-CPUTime -exePath $rustExe -args @($input, $outputRust)

        $results += [PSCustomObject]@{
            Tool = $tool.Name
            InputSize = $suffix
            Language = "Rust"
            PeakMemoryMB = $memRust
            CPUTimeMS = $cpuRust
        }

        # C#: Memory and CPU measured separately
        $csharpExe = Join-Path $PWD $tool.CSharp
        $memCSharp = Measure-PeakMemoryUsage -exePath $csharpExe -args @($input, $outputCSharp)
        $cpuCSharp = Measure-CPUTime -exePath $csharpExe -args @($input, $outputCSharp)

        $results += [PSCustomObject]@{
            Tool = $tool.Name
            InputSize = $suffix
            Language = "C#"
            PeakMemoryMB = $memCSharp
            CPUTimeMS = $cpuCSharp
        }
    }
}

# Output table and export
$results | Format-Table Tool, InputSize, Language, PeakMemoryMB, CPUTimeMS
$results | Export-Csv -Path "memory_cpu_benchmarks.csv" -NoTypeInformation
