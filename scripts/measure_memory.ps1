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

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exePath
    $psi.Arguments = [string]::Join(' ', $arguments)
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $proc.Start() | Out-Null

    $output = $proc.StandardOutput.ReadToEnd()
    $proc.WaitForExit()
    $sw.Stop()

    return @{
        Time = [math]::Round($sw.Elapsed.TotalMilliseconds, 3)
        Output = $output.Trim()
    }
}

$tools = @(
    @{
        Name = "StreamProcessor"
        Rust = "RustProjects\target\release\csv_transform.exe"
        CSharp = "CSharpProjects\CsvTransformer\bin\Release\net9.0\CsvTransformer.exe"
        CSharpRustCLI = "CSharpProjectsUseCLIRust\CsvStreamProcessor\bin\release\net9.0\CsvStreamProcessor.exe"
        CSharpRustDLL = "CharpProjectsUseDLLRust\CsharptCsvStreamProcessorUseRustDll\bin\Release\net9.0\CsharptCsvStreamProcessorUseRustDll.exe"
    },
    @{
        Name = "BatchProcessor"
        Rust = "RustProjects\target\release\batch_job.exe"
        CSharp = "CSharpProjects\BatchProcessor\bin\Release\net9.0\BatchProcessor.exe"
        CSharpRustCLI = "CSharpProjectsUseCLIRust\CsvBatchProcessor\bin\release\net9.0\CsvBatchProcessor.exe"
        CSharpRustDLL = "CharpProjectsUseDLLRust\CsharptCsvBatchProcessorUseRustDll\bin\Release\net9.0\CsharptCsvBatchProcessorUseRustDll.exe"
    },
    @{
        Name = "ParallelBatchProcessor"
        Rust = "RustProjects\target\release\parallel_batch_job.exe"
        RustOptimized = "RustProjects\target\release\parallel_batch_job_for_huge_file.exe"
        CSharp = "CSharpProjects\ParallelBatchProcessor\bin\Release\net9.0\ParallelBatchProcessor.exe"
        CSharpRustCLI = "CSharpProjectsUseCLIRust\CsvParallelBatchProcessor\bin\release\net9.0\CsvParallelBatchProcessor.exe"
        CSharpRustDLL = "CharpProjectsUseDLLRust\CsharptCsvParallelBatchProcessorUseRustDll\bin\Release\net9.0\CsharptCsvParallelBatchProcessorUseRustDll.exe"
    }
)

$inputs = @("small_input.csv", "large_input.csv", "huge_input.csv")
$results = @()
for ($i = 0; $i -lt 3; $i++) {
    foreach ($tool in $tools) {
        foreach ($input in $inputs) {
            $suffix = ($input -replace "_input.csv", "")
            $inputPath = Join-Path $PWD "results\$input"
            $outputPath = Join-Path $PWD ("results\output_memory_{0}_{1}_{2}.csv" -f $tool.Name, $suffix, $lang)


            $languages = @("Rust", "CSharp", "CSharpRustCLI", "CSharpRustDLL")
            foreach ($lang in $languages) {
                $exePath = Join-Path $PWD $tool[$lang]
                $mem = Measure-PeakMemoryUsage -exePath $exePath -arguments @($inputPath, $outputPath)
                # $cpu = Measure-CPUTime -exePath $exePath -arguments @($inputPath, $outputPath)
                $cpuResult = Measure-CPUTime -exePath $exePath -arguments @($inputPath, $outputPath)
                $cpu = $cpuResult.Time
                $output = $cpuResult.Output

                Write-Host "`n[$lang - $input] Output from EXE:`n$output`n"
                $results += [PSCustomObject]@{
                    loop = $i
                    Scenario = $tool.Name
                    InputSize = $suffix
                    Tool = $lang
                    PeakMemoryMB = $mem
                    CPUTimeMS = $cpu
                    ConsoleOutput = $output
                }
            }

            # Add optimized Rust only for huge file
            if ($tool.RustOptimized) {
                $exePath = Join-Path $PWD $tool.RustOptimized
                $mem = Measure-PeakMemoryUsage -exePath $exePath -arguments @($inputPath, $outputPath)
                # $cpu = Measure-CPUTime -exePath $exePath -arguments @($inputPath, $outputPath)
                $cpuResult = Measure-CPUTime -exePath $exePath -arguments @($inputPath, $outputPath)
                $cpu = $cpuResult.Time
                $output = $cpuResult.Output
                $results += [PSCustomObject]@{
                    Scenario = $tool.Name
                    InputSize = $suffix
                    Tool = "RustOptimized"
                    PeakMemoryMB = $mem
                    CPUTimeMS = $cpu
                    ConsoleOutput = $output
                }
            }
        }
    }
}
$timeStamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$results | Format-Table loop, Scenario, InputSize, Tool, PeakMemoryMB, CPUTimeMS, ConsoleOutput -AutoSize
$results | Export-Csv -Path "results\memory_cpu_benchmarks_$timeStamp.csv" -NoTypeInformation

