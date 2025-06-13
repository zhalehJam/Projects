Set-Location "E:\Education\Saxion\Internship\Projects"

# Paths to executables
$RustCsvTransformer = "E:\Education\Saxion\Internship\Projects\RustProjects\target\release\csv_transform.exe"
$csharpCsvTransformer = "E:\Education\Saxion\Internship\Projects\CSharpProjects\CsvTransformer\bin\Release\net9.0\CsvTransformer.exe"
$csharpCsvStreamProcessorUseRustCli = "E:\Education\Saxion\Internship\Projects\CSharpProjectsUseCLIRust\CsvStreamProcessor\bin\release\net9.0\CsvStreamProcessor.exe"
$csharpCsvStreamProcessorUseRustDll = "E:\Education\Saxion\Internship\Projects\CharpProjectsUseDLLRust\CsharptCsvStreamProcessorUseRustDll\bin\Release\net9.0\CsharptCsvStreamProcessorUseRustDll.exe"

$rustBatch = "E:\Education\Saxion\Internship\Projects\RustProjects\target\release\batch_job.exe"
$csharpBatch = "E:\Education\Saxion\Internship\Projects\CSharpProjects\BatchProcessor\bin\Release\net9.0\BatchProcessor.exe"
$csharpCsvBatchProcessorUseRustCli="E:\Education\Saxion\Internship\Projects\CSharpProjectsUseCLIRust\CsvBatchProcessor\bin\release\net9.0\CsvBatchProcessor.exe"
$csharpCsvBatchProcessorUseRustDll="E:\Education\Saxion\Internship\Projects\CharpProjectsUseDLLRust\CsharptCsvBatchProcessorUseRustDll\bin\Release\net9.0\CsharptCsvBatchProcessorUseRustDll.exe"

$rustParallel = "E:\Education\Saxion\Internship\Projects\RustProjects\target\release\parallel_batch_job.exe"
$csharpParallel = "E:\Education\Saxion\Internship\Projects\CSharpProjects\ParallelBatchProcessor\bin\Release\net9.0\ParallelBatchProcessor.exe"
$csharpCsvParallelBatchProcessorUseRustCli="E:\Education\Saxion\Internship\Projects\CSharpProjectsUseCLIRust\CsvParallelBatchProcessor\bin\release\net9.0\CsvParallelBatchProcessor.exe"
$csharpCsvParallelBatchProcessorUseRustDll = "E:\Education\Saxion\Internship\Projects\CharpProjectsUseDLLRust\CsharptCsvParallelBatchProcessorUseRustDll\bin\Release\net9.0\CsharptCsvParallelBatchProcessorUseRustDll.exe"
# Input sizes
$inputs = @( "results\huge_input.csv") # Add "large_input.csv", "huge_input.csv" as needed  "results\small_input.csv","results\large_input.csv",

foreach ($input in $inputs) {
    # $suffix = ($input -replace "_input.csv", "")
    # $suffix= $suffix -replace "results\\", ""
    $suffix = [System.IO.Path]::GetFileNameWithoutExtension($input) -replace "_input", ""

    Write-Host "Benchmarking CSV Transformer [$suffix]"

    # hyperfine --warmup 10 --runs 10 --show-output `
    #     "`"$RustCsvTransformer`" `"$input`" `"results\rustTransformer_output_$suffix.csv`"" `
    #     "`"$csharpCsvTransformer`" `"$input`" `"results\csharpTransformer_output_$suffix.csv`"" `
    #     "`"$csharpCsvStreamprocessorUseRustCli`" `"$input`" `"results\csharpTransformerRustCli_output_$suffix.csv`"" `
    #     "`"$csharpCsvStreamprocessorUseRustDll`" `"$input`" `"results\csharpTransformerRustDll_output_$suffix.csv`"" `
    #     --export-markdown "results\benchmark_transformer_$suffix.md"

    # Write-Host "Benchmarking Batch Processor [$suffix]"

    # hyperfine --warmup 10 --runs 10 --show-output `
    #     "$rustBatch $input results\rustBatch_output_$suffix.csv" `
    #     "$csharpBatch $input results\csharpBatch_output_$suffix.csv" `
    #     "$csharpCsvBatchProcessorUseRustCli $input results\csharpBatchRustCli_output_$suffix.csv" `
    #     "$csharpCsvBatchProcessorUseRustDll $input results\csharpBatchRustDll_output_$suffix.csv" `
    #     --export-markdown "results\benchmark_batch_$suffix.md"

    Write-Host "Benchmarking Parallel Batch Processor [$suffix]"

    hyperfine --warmup 10 --runs 10 --show-output `
        "$rustParallel $input results\rustParallel_output_$suffix.csv" `
        "$csharpParallel $input results\csharpParallel_output_$suffix.csv" `
        "$csharpCsvParallelBatchProcessorUseRustCli $input results\csharpParallelRustCli_output_$suffix.csv" `
        "$csharpCsvParallelBatchProcessorUseRustDll $input results\csharpParallelRustDll_output_$suffix.csv" `
        --export-markdown "results\benchmark_parallel_$suffix.md"
}

Write-Host "All benchmarks completed."


