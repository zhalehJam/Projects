Set-Location "E:\Education\Saxion\Internship\Projects"

function Measure-PeakMemoryUsage {
    param (
        [string]$exePath,
        [string[]]$arguments
    )
    $proc = Start-Process -FilePath $exePath -ArgumentList $arguments -PassThru
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
    $duration = Measure-Command {
        & $exePath @arguments
    }
    return [math]::Round($duration.TotalMilliseconds, 3)
}

$tools = @(
    # @{
    #     Name = "CSVTransformer"
    #     Rust = "RustProjects\target\release\csv_transform.exe"
    #     CSharp = "CSharpProjects\CsvTransformer\bin\Release\net9.0\CsvTransformer.exe"
    #     CSharpCLI = "CSharpProjectsUseCLIRust\CsvStreamProcessor\bin\release\net9.0\CsvStreamProcessor.exe"
    #     CSharpDLL = "CharpProjectsUseDLLRust\CsharptCsvStreamProcessorUseRustDll\bin\Release\net9.0\CsharptCsvStreamProcessorUseRustDll.exe"
    # },
    # @{
    #     Name = "BatchProcessor"
    #     Rust = "RustProjects\target\release\batch_job.exe"
    #     CSharp = "CSharpProjects\BatchProcessor\bin\Release\net9.0\BatchProcessor.exe"
    #     CSharpCLI = "CSharpProjectsUseCLIRust\CsvBatchProcessor\bin\release\net9.0\CsvBatchProcessor.exe"
    #     CSharpDLL = "CharpProjectsUseDLLRust\CsharptCsvBatchProcessorUseRustDll\bin\Release\net9.0\CsharptCsvBatchProcessorUseRustDll.exe"
    # },
    @{
        Name = "ParallelBatchProcessor"
        Rust = "RustProjects\target\release\parallel_batch_job.exe"
        RustOptimized = "RustProjects\target\release\parallel_batch_job_for_huge_file.exe"
        CSharp = "CSharpProjects\ParallelBatchProcessor\bin\Release\net9.0\ParallelBatchProcessor.exe"
        CSharpCLI = "CSharpProjectsUseCLIRust\CsvParallelBatchProcessor\bin\release\net9.0\CsvParallelBatchProcessor.exe"
        CSharpDLL = "CharpProjectsUseDLLRust\CsharptCsvParallelBatchProcessorUseRustDll\bin\Release\net9.0\CsharptCsvParallelBatchProcessorUseRustDll.exe"
    }
)

$inputs = @("small_input.csv", "large_input.csv", "huge_input.csv")
$results = @()

foreach ($tool in $tools) {
    foreach ($input in $inputs) {
        $suffix = ($input -replace "_input.csv", "")
        $inputPath = Join-Path $PWD "results\$input"
        $outputPath = Join-Path $PWD ("results\output_memory_{0}_{1}_{2}.csv" -f $tool.Name, $suffix, $lang)


        $languages = @("Rust", "CSharp", "CSharpCLI", "CSharpDLL")
        foreach ($lang in $languages) {
            $exePath = Join-Path $PWD $tool[$lang]
            $mem = Measure-PeakMemoryUsage -exePath $exePath -arguments @($inputPath, $outputPath)
            $cpu = Measure-CPUTime -exePath $exePath -arguments @($inputPath, $outputPath)
            $results += [PSCustomObject]@{
                Tool = $tool.Name
                InputSize = $suffix
                Language = $lang
                PeakMemoryMB = $mem
                CPUTimeMS = $cpu
            }
        }

        # Add optimized Rust only for huge file
        if ($tool.RustOptimized) {
            $exePath = Join-Path $PWD $tool.RustOptimized
            $mem = Measure-PeakMemoryUsage -exePath $exePath -arguments @($inputPath, $outputPath)
            $cpu = Measure-CPUTime -exePath $exePath -arguments @($inputPath, $outputPath)
            $results += [PSCustomObject]@{
                Tool = $tool.Name
                InputSize = $suffix
                Language = "RustOptimized"
                PeakMemoryMB = $mem
                CPUTimeMS = $cpu
            }
        }
    }
}

$results | Format-Table Tool, InputSize, Language, PeakMemoryMB, CPUTimeMS
$results | Export-Csv -Path "results\memory_cpu_benchmarks.csv" -NoTypeInformation

