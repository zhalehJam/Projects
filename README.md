# CLI CSV Processing Comparison

This repository contains **four main projects** for high-performance CSV processing, implemented in both **Rust** and **C#**. The goal is to compare their execution models, memory usage, speed, and parallel performance. We also provide scripts for automated benchmarking.

---

## 📦 Project Overview

### 1. **Manual Stream Processor**
- **Rust:** `csv_transform.rs`
- **C#:** `CsvTransformer` (`CsvProcessorManual.cs`)
- **Description:** Reads and processes each CSV line one-by-one, filtering or transforming as needed, and writes output immediately. Minimal memory usage.

### 2. **Batch Job Processor**
- **Rust:** `batch_job.rs`
- **C#:** `BatchJob.cs`
- **Description:** Reads the CSV, aggregates/group data (e.g., by age group) in memory, then writes a summary output. Higher memory usage, but enables aggregation.

### 3. **Parallel Batch Job**
- **Rust:** `parallel_batch_job.rs`
- **C#:** `BatchJobParallel.cs`
- **Description:** Reads the CSV in chunks, processes each chunk in parallel threads, aggregates results, and merges them. Fast and scalable for large files.

### 4. **Polars/Streaming Batch Job (Rust only)**
- **Rust:** `parallel_batch_job_for_huge_file.rs`
- **Description:** Uses the Polars library's streaming/lazy API for highly efficient, parallel, and low-memory batch processing on huge CSV files.

---

## ⚙️ Execution Models

### Manual Stream Processor

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
│ Filter/Write │
└────┬─────────┘
     ↓
Repeat for each line (no state kept)
```

---

### Batch Job Processor

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
│ Update aggregation in mem  │◄───┐
└────┬───────────────────────┘    │
     ↓                            │
Repeat for all lines ─────────────┘

After reading all:
     ↓
┌────────────────────────┐
│ Write summary to output│
└────────────────────────┘
```

---

### Parallel Batch Job

```
┌────────────┐
│ input.csv  │
└────┬───────┘
     ↓
┌──────────────────────────────┐
│ Read chunk of N lines        │
└────┬─────────────────────────┘
     ↓
┌──────────────────────────────┐
│ Process chunk in parallel    │
│ (threads/tasks)              │
└────┬─────────────────────────┘
     ↓
┌──────────────────────────────┐
│ Merge local aggregates       │
└────┬─────────────────────────┘
     ↓
After all chunks:
┌────────────────────────┐
│ Write summary to output│
└────────────────────────┘
```

---

### Polars/Streaming Batch Job (Rust)

```
┌────────────┐
│ input.csv  │
└────┬───────┘
     ↓
┌──────────────────────────────┐
│ Polars streaming engine      │
│ (parallel, chunked, lazy)    │
└────┬─────────────────────────┘
     ↓
┌──────────────────────────────┐
│ Group/aggregate in streaming │
└────┬─────────────────────────┘
     ↓
┌────────────────────────┐
│ Write summary to output│
└────────────────────────┘
```

---

## 🛠️ Benchmarking & Profiling Scripts

### Memory & CPU Usage

- **PowerShell script:** `measure_memory.ps1`
    - Runs each CLI tool and records peak memory and CPU time.
    - Example usage:
      ```powershell
      ./measure_memory.ps1
      ```
    - Make sure to set the correct paths for each binary.

### Speed & Performance

- **[hyperfine](https://github.com/sharkdp/hyperfine):** Used to benchmark execution time.
    - Example usage:
      ```powershell
      hyperfine --warmup 1 --show-output "path\to\rust_tool.exe input.csv output.csv" "path\to\csharp_tool.exe input.csv output.csv"
      ```
    - Results can be exported to Markdown for reporting.

---

## 📝 Notes

- **Rust:** Build with `cargo build --release`
- **C#:** Build with `dotnet build -c Release`
- For parallel and streaming jobs, ensure dependencies (e.g., Polars for Rust) are up to date and have the correct features enabled.
- All tools accept the same CLI arguments: `<input.csv> <output.csv>`

---

## 📊 Results

- See the generated `*_benchmark.md` files for detailed performance and memory usage comparisons.

---

## License

MIT