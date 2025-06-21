Set-Location "E:\Education\Saxion\Internship\Projects"

# Paths to executables
$tools = @{
    Transformer = @(
        @{ Name = "Rust"; Cmd = "RustProjects\target\release\csv_transform.exe" }
        @{ Name = "C#"; Cmd = "CSharpProjects\CsvTransformer\bin\Release\net9.0\CsvTransformer.exe" }
        @{ Name = "C# + Rust CLI"; Cmd = "CSharpProjectsUseCLIRust\CsvStreamProcessor\bin\release\net9.0\CsvStreamProcessor.exe" }
        @{ Name = "C# + Rust DLL"; Cmd = "CharpProjectsUseDLLRust\CsharptCsvStreamProcessorUseRustDll\bin\Release\net9.0\CsharptCsvStreamProcessorUseRustDll.exe" }
    )
    Batch = @(
        @{ Name = "Rust"; Cmd = "RustProjects\target\release\batch_job.exe" }
        @{ Name = "C#"; Cmd = "CSharpProjects\BatchProcessor\bin\Release\net9.0\BatchProcessor.exe" }
        @{ Name = "C# + Rust CLI"; Cmd = "CSharpProjectsUseCLIRust\CsvBatchProcessor\bin\release\net9.0\CsvBatchProcessor.exe" }
        @{ Name = "C# + Rust DLL"; Cmd = "CharpProjectsUseDLLRust\CsharptCsvBatchProcessorUseRustDll\bin\Release\net9.0\CsharptCsvBatchProcessorUseRustDll.exe" }
    )
    Parallel = @(
        @{ Name = "Rust"; Cmd = "RustProjects\target\release\parallel_batch_job.exe" }
        @{ Name = "C#"; Cmd = "CSharpProjects\ParallelBatchProcessor\bin\Release\net9.0\ParallelBatchProcessor.exe" }
        @{ Name = "C# + Rust CLI"; Cmd = "CSharpProjectsUseCLIRust\CsvParallelBatchProcessor\bin\release\net9.0\CsvParallelBatchProcessor.exe" }
        @{ Name = "C# + Rust DLL"; Cmd = "CharpProjectsUseDLLRust\CsharptCsvParallelBatchProcessorUseRustDll\bin\Release\net9.0\CsharptCsvParallelBatchProcessorUseRustDll.exe" }
    )
}

# Input sizes
$inputs = @( "results\small_input.csv", "results\large_input.csv", "results\huge_input.csv") #"results\small_input.csv", "results\large_input.csv", 

# Store benchmark results for table + CSV
$results = @()

foreach ($input in $inputs) {
    $inputName = [System.IO.Path]::GetFileNameWithoutExtension($input) -replace "_input", ""

    foreach ($scenario in $tools.Keys) {
        Write-Host "Benchmarking $scenario [$inputName]..."

        $args = @()
        foreach ($tool in $tools[$scenario]) {
            $exePath = "E:\Education\Saxion\Internship\Projects\$($tool.Cmd)"
            $cmd = "`"$exePath`" $input results\output_dummy.csv"
            $args += $cmd
        }

        $jsonPath = "results\benchmark_${scenario.ToLower()}_${inputName}.json"

        hyperfine @args --warmup 2 --runs 2 --export-json $jsonPath | Out-Null

        # Parse and extract best time per tool
        $json = Get-Content $jsonPath | ConvertFrom-Json
        for ($i = 0; $i -lt $json.results.Count; $i++) {
            $toolLabel = $tools[$scenario][$i].Name
            $bestTimeMs = [math]::Round($json.results[$i].median * 1000, 2)
            $stddevMs = [math]::Round($json.results[$i].stddev * 1000, 2)
            $results += [PSCustomObject]@{
                Scenario = $scenario
                Input    = $inputName
                Tool     = $toolLabel
                "Time (ms)" = $bestTimeMs
                "StdDev (ms)" = $stddevMs
            }
        }
    }
}

# Special case: Rust parallel batch optimized for huge file
$hugeInput = "results\huge_input.csv"
$output = "results\rustParallelHugeSpecial_output_huge.csv"
$exeSpecial = "E:\Education\Saxion\Internship\Projects\RustProjects\target\release\parallel_batch_job_for_huge_file.exe"

Write-Host "Benchmarking Special Rust Parallel Optimized for Huge File..."

$cmdSpecial = "`"$exeSpecial`" $hugeInput $output"
$jsonSpecial = "results\benchmark_parallel_special_huge.json"

hyperfine $cmdSpecial --export-json $jsonSpecial | Out-Null

$json = Get-Content $jsonSpecial | ConvertFrom-Json
$median = [math]::Round($json.results[0].median * 1000, 2)
$stddev = [math]::Round($json.results[0].stddev * 1000, 2)

$results += [PSCustomObject]@{
    Scenario = "Parallel (Optimized)"
    Input = "huge"
    Tool = "Rust Special"
    "Time (ms)" = $median
    "StdDev (ms)" = $stddev
}




# Output results table
$results | Format-Table -AutoSize

# Export to CSV
# $results | Export-Csv -Path "results\benchmark_summary.csv" -NoTypeInformation -Encoding UTF8

Write-Host "`Benchmarking complete. Results saved to results\benchmark_summary.csv"
