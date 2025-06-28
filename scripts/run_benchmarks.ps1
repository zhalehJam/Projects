Set-Location "E:\Education\Saxion\Internship\Projects"

# Paths to executables
$tools = @{
    StreamProcessor = @(
        @{ Name = "Rust"; Cmd = "RustProjects\target\release\csv_transform.exe" }
        @{ Name = "CSharp"; Cmd = "CSharpProjects\CsvTransformer\bin\Release\net9.0\CsvTransformer.exe" }
        @{ Name = "CSharpRustCLI"; Cmd = "CSharpProjectsUseCLIRust\CsvStreamProcessor\bin\release\net9.0\CsvStreamProcessor.exe" }
        @{ Name = "CSharpRustDLL"; Cmd = "CharpProjectsUseDLLRust\CsharptCsvStreamProcessorUseRustDll\bin\Release\net9.0\CsharptCsvStreamProcessorUseRustDll.exe" }
    )
    BatchProcessor = @(
        @{ Name = "Rust"; Cmd = "RustProjects\target\release\batch_job.exe" }
        @{ Name = "CSharp"; Cmd = "CSharpProjects\BatchProcessor\bin\Release\net9.0\BatchProcessor.exe" }
        @{ Name = "CSharpRustCLI"; Cmd = "CSharpProjectsUseCLIRust\CsvBatchProcessor\bin\release\net9.0\CsvBatchProcessor.exe" }
        @{ Name = "CSharpRustDLL"; Cmd = "CharpProjectsUseDLLRust\CsharptCsvBatchProcessorUseRustDll\bin\Release\net9.0\CsharptCsvBatchProcessorUseRustDll.exe" }
    )
    ParallelBatchProcessor = @(
        @{ Name = "Rust"; Cmd = "RustProjects\target\release\parallel_batch_job.exe" }
        @{ Name = "CSharp"; Cmd = "CSharpProjects\ParallelBatchProcessor\bin\Release\net9.0\ParallelBatchProcessor.exe" }
        @{ Name = "CSharpRustCLI"; Cmd = "CSharpProjectsUseCLIRust\CsvParallelBatchProcessor\bin\release\net9.0\CsvParallelBatchProcessor.exe" }
        @{ Name = "CSharpRustDLL"; Cmd = "CharpProjectsUseDLLRust\CsharptCsvParallelBatchProcessorUseRustDll\bin\Release\net9.0\CsharptCsvParallelBatchProcessorUseRustDll.exe" }
        @{ Name = "RustOptimized"; Cmd = "RustProjects\target\release\parallel_batch_job_for_huge_file.exe"}
    )
}

# Input sizes
$inputs = @( "results\small_input.csv", "results\large_input.csv", "results\huge_input.csv") #"results\small_input.csv", "results\large_input.csv", 

# Store benchmark results for table + CSV
$results = @()
for ($j = 0; $j -lt 3; $j++) {
    foreach ($input in $inputs) {
        $inputName = [System.IO.Path]::GetFileNameWithoutExtension($input) -replace "_input", ""

        foreach ($scenario in $tools.Keys) {
            Write-Host "Benchmarking $scenario [$inputName]..."

            $args = @()
            foreach ($tool in $tools[$scenario]) {
                $exePath = "E:\Education\Saxion\Internship\Projects\$($tool.Cmd)"
                $outputFile = "results\output_benchmark_{0}_{1}_{2}.csv" -f $tool.Name, $scenario, $inputName
                $cmd = "`"$exePath`" $input $outputFile"
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
                    loop = $j
                    Scenario = $scenario
                    InputSize   = $inputName
                    Tool     = $toolLabel
                    "Time (ms)" = $bestTimeMs
                    "StdDev (ms)" = $stddevMs
                }
            }
        }
    }
}

# Output results table
$results | Format-Table -AutoSize
$timeStamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
# Export to CSV
$results | Export-Csv -Path "results\benchmark_summary_$timeStamp.csv" -NoTypeInformation -Encoding UTF8

Write-Host "`Benchmarking complete. Results saved to results\benchmark_summary_$timeStamp.csv"
