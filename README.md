# CLI Comparison Project\n\nThis repo contains two CLI tools:\n- : Rust\n- : C#\n\nUse hyperfine to benchmark them.\n

### 🧠 Data Flow: Manual vs Batch Job Processing

#### 🟩 Manual Stream Processor: `read → act → forget`

```
┌────────────┐
│ input.csv  │
└────┬───────┘
     ↓
┌──────────────┐
│ Read 1 line  │
└────┬─────────┘
     ↓
┌──────────────┐
│ Filter/Modify│
└────┬─────────┘
     ↓
┌──────────────┐
│ Write output │
└────┬─────────┘
     ↓
 Repeat for next line (no memory retained)
```

---

#### 🟦 Batch Job Processor: `read → store → aggregate → write`

```
┌────────────┐
│ input.csv  │
└────┬───────┘
     ↓
┌──────────────┐
│ Read 1 line  │
└────┬─────────┘
     ↓
┌────────────────────────────┐
│ Update count in memory map│  ◄───┐
└────┬───────────────────────┘     │
     ↓                             │
 Repeat for all lines ─────────────┘

After reading all:
     ↓
┌────────────────────────┐
│ Write summary to output│
└────────────────────────┘
```

### ✅ Summary

- The **manual stream processor** reacts row-by-row and keeps no memory.
- The **batch job** tracks and aggregates data across the entire dataset, producing a structured summary.

Use this distinction to justify design decisions in benchmarks, strategy analysis, and reporting.

### ▶️ How to Profile Resource Usage

Use the included PowerShell script `measure_memory.ps1` to measure peak memory and CPU time.

```powershell
# Run from project root in PowerShell
./measure_memory.ps1
```
Ensure the paths inside the script point to:
- Rust release binary: `target/release/batch_job.exe`
- C# release binary: `bin/Release/net9.0/CsvProcessor.exe`




Use [`hyperfine`](https://github.com/sharkdp/hyperfine) to measure and compare execution time:

Ensure the paths match your latest build:
- Rust: `cargo build --release`
- C#: `dotnet build -c Release`


```powershell
# Run from project root in PowerShell
hyperfine --warmup 1 --show-output   "/e/Education/Saxion/Internship/Projects/csv_processor_rust/target/release/cli_tool.exe large_input.csv output_rust.csv"   "/e/Education/Saxion/Internship/Projects/CsvProcessor/bin/Release/net9.0/CsvProcessor.exe large_input.csv output_csharp.csv"   --export-markdown manual_benchmark.md
```

```powershell
# Run from project root in PowerShell
hyperfine --warmup 1 --show-output   "/e/Education/Saxion/Internship/Projects/csv_processor_rust/target/release/batch_job.exe large_input.csv output_rust.csv"   "/e/Education/Saxion/Internship/Projects/CsvProcessor/bin/Release/net9.0/CsvProcessor.exe large_input.csv output_csharp.csv"   --export-markdown benchmark.md
```


```powershell
hyperfine --warmup 1 --show-output   "/e/Education/Saxion/Internship/Projects/csv_processor_rust/target/release/batch_job_parallel.exe large_input.csv output_rust.csv"   "/e/Education/Saxion/Internship/Projects/CsvProcessor/bin/Release/net9.0/CsvProcessor.exe large_input.csv output_csharp.csv"   --export-markdown Parallel_benchmark.md
```

```powershell
hyperfine --warmup 1 --show-output `
'"E:\Education\Saxion\Internship\Projects\CsvTools\CallRustTool\bin\Release\net9.0\CallRustTool.exe" "E:\Education\Saxion\Internship\Projects\results\small_input.csv" "E:\Education\Saxion\Internship\Projects\results\output_rust.csv"' `
'"E:\Education\Saxion\Internship\Projects\CsvTools\CsvTransformer\bin\Release\net9.0\CsvTransformer.exe" "E:\Education\Saxion\Internship\Projects\results\small_input.csv" "E:\Education\Saxion\Internship\Projects\results\output_csharp.csv"' `
--export-markdown manual_benchmark.md

```
hyperfine --warmup 1 --show-output '"E:\Education\Saxion\Internship\Projects\rust_lib\TestLibraryProject\CsvProcessor\bin\Release\net9.0\CsvProcessor.exe" "E:\Education\Saxion\Internship\Projects\results\small_input.csv" "E:\Education\Saxion\Internship\Projects\results\output_rust.csv"' '"E:\Education\Saxion\Internship\Projects\CsvTools\CsvTransformer\bin\Release\net9.0\CsvTransformer.exe" "E:\Education\Saxion\Internship\Projects\results\small_input.csv" "E:\Education\Saxion\Internship\Projects\results\output_csharp.csv"' --export-markdown csv_transform_benchmark.md

### 📝 Notes
dotnet new console -n threadcheck
dotnet sln add .\threadcheck\threadcheck.csproj
dotnet add package System.Threading.Channels
dotnet new sln -n CsharpProjectUseRustCLI      





hyperfine --warmup 1 --show-output '"E:\Education\Saxion\Internship\Projects\rust_lib\TestLibraryProject\CsvProcessor\bin\Release\net9.0\CsvProcessor.exe" "E:\Education\Saxion\Internship\Projects\results\small_input.csv" "E:\Education\Saxion\Internship\Projects\results\output_rust.csv"' '"E:\Education\Saxion\Internship\Projects\CsvTools\CsvTransformer\bin\Release\net9.0\CsvTransformer.exe" "E:\Education\Saxion\Internship\Projects\results\small_input.csv" "E:\Education\Saxion\Internship\Projects\results\output_csharp.csv"' '"E:\Education\Saxion\Internship\Projects\csv_processor_rust\target\release\csv_transform.exe" "E:\Education\Saxion\Internship\Projects\results\small_input.csv" "E:\Education\Saxion\Internship\Projects\results\output_rust.csv"' '"E:\Education\Saxion\Internship\Projects\CsvTools\CallRustTool\bin\Release\net9.0\CallRustTool.exe" "E:\Education\Saxion\Internship\Projects\results\small_input.csv" "E:\Education\Saxion\Internship\Projects\results\output_rust.csv"'--export-markdown csv_transform_benchmark.md