Set-Location "E:\Education\Saxion\Internship\Projects"

# Paths to executables
$RustCsvTransformer = "E:\Education\Saxion\Internship\Projects\csv_processor_rust\target\release\csv_transform.exe"
$csharpCsvTransformer = "E:\Education\Saxion\Internship\Projects\CsvTools\CsvTransformer\bin\Release\net9.0\CsvTransformer.exe"

$rustBatch = "E:\Education\Saxion\Internship\Projects\csv_processor_rust\target\release\batch_job.exe"
$csharpBatch = "E:\Education\Saxion\Internship\Projects\CsvTools\BatchProcessor\bin\Release\net9.0\BatchProcessor.exe"

$rustParallel = "E:\Education\Saxion\Internship\Projects\csv_processor_rust\target\release\parallel_batch_job.exe"
$csharpParallel = "E:\Education\Saxion\Internship\Projects\CsvTools\ParallelBatchProcessor\bin\Release\net9.0\ParallelBatchProcessor.exe"

# Input sizes
$inputs = @("small_input.csv","large_input.csv", "huge_input.csv") # Add "large_input.csv", "huge_input.csv" as needed

foreach ($input in $inputs) {
    $suffix = ($input -replace "_input.csv", "")

    Write-Host "Benchmarking CSV Transformer [$suffix]"

    hyperfine --warmup 1 --show-output `
        "$RustCsvTransformer $input rustTransformer_output_$suffix.csv" `
        "$csharpCsvTransformer $input csharpTransformer_output_$suffix.csv" `
        --export-markdown "benchmark_transformer_$suffix.md"

    Write-Host "Benchmarking Batch Processor [$suffix]"

    hyperfine --warmup 1 --show-output `
        "$rustBatch $input rustBatch_output_$suffix.csv" `
        "$csharpBatch $input csharpBatch_output_$suffix.csv" `
        --export-markdown "benchmark_batch_$suffix.md"

    Write-Host "Benchmarking Parallel Batch Processor [$suffix]"

    hyperfine --warmup 1 --show-output `
        "$rustParallel $input rustParallel_output_$suffix.csv" `
        "$csharpParallel $input csharpParallel_output_$suffix.csv" `
        --export-markdown "benchmark_parallel_$suffix.md"
}

Write-Host "All benchmarks completed."
