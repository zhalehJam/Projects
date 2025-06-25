// Build: cargo build --release --bin batch_job_parallel

use std::env;
use std::error::Error;
use std::fs::File;
use std::io::BufReader;
use std::time::Instant;

use csv::{ReaderBuilder, StringRecord};
use rayon::prelude::*;
use serde::Deserialize;
use sysinfo::{System, Process};

/// Structure for deserializing each user row
#[derive(Debug, Deserialize)]
struct User {
    id: u32,
    name: String,
    email: String,
    age: u8,
}

/// Convert a raw age into a bucketed age group index (e.g., 30 → 3 for "30-39")
fn age_group_index(age: u8) -> usize {
    (age / 10) as usize
}

/// Core logic: parallel batch processing and aggregation
fn parallel_age_group_counts(input_path: &str, output_path: &str) -> Result<(), Box<dyn Error>> {
    let input = File::open(input_path)?;
    let reader = BufReader::with_capacity(65536, input);
    let mut rdr = ReaderBuilder::new().has_headers(true).from_reader(reader);

    // Read header
    let headers = rdr.headers()?.clone();

    // We'll use 13 buckets for ages 0-129 (0-9, 10-19, ..., 120-129)
    const BUCKETS: usize = 13;
    let chunk_size = 1000;

    // Prepare for chunked parallel processing
    let mut records = Vec::with_capacity(chunk_size);
    let mut global_counts = vec![0u32; BUCKETS];

    loop {
        records.clear();
        // Read up to chunk_size records
        for _ in 0..chunk_size {
            let mut record = StringRecord::new();
            if !rdr.read_record(&mut record)? {
                break;
            }
            records.push(record.clone());
        }
        if records.is_empty() {
            break;
        }

        // Process this chunk in parallel
        let local_counts: Vec<u32> = records
            .par_iter()
            .map(|rec| {
                let user: User = rec.deserialize(Some(&headers)).unwrap();
                let mut counts = vec![0u32; BUCKETS];
                let idx = age_group_index(user.age);
                if idx < BUCKETS {
                    counts[idx] += 1;
                }
                counts
            })
            .reduce(
                || vec![0u32; BUCKETS],
                |mut a, b| {
                    for (i, v) in b.into_iter().enumerate() {
                        a[i] += v;
                    }
                    a
                },
            );

        // Merge local_counts into global_counts
        for (i, v) in local_counts.into_iter().enumerate() {
            global_counts[i] += v;
        }
    }

    // Write results to output CSV
    let output_file = File::create(output_path)?;
    let mut wtr = csv::WriterBuilder::new().from_writer(output_file);

    wtr.write_record(&["age_group", "count"])?;
    for (i, count) in global_counts.iter().enumerate() {
        let start = i * 10;
        let end = start + 9;
        wtr.write_record(&[format!("{}-{}", start, end), count.to_string()])?;
    }
    wtr.flush()?;
    Ok(())
}

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        eprintln!("Usage: batch_job_parallel <input.csv> <output.csv>");
        std::process::exit(1);
    }

    // --- Memory and time measurement ---
    let mut sys = System::new();
    sys.refresh_processes();
    let pid = sysinfo::get_current_pid().unwrap();
    let process = sys.process(pid).unwrap();
    let base_memory = process.memory();

    let start = Instant::now();

    // Spawn a thread to poll for peak memory
    let peak_mem = std::sync::Arc::new(std::sync::atomic::AtomicU64::new(base_memory));
    let peak_mem_clone = peak_mem.clone();
    let running = std::sync::Arc::new(std::sync::atomic::AtomicBool::new(true));
    let running_clone = running.clone();

    let handle = std::thread::spawn(move || {
        let mut sys = System::new();
        while running_clone.load(std::sync::atomic::Ordering::Relaxed) {
            sys.refresh_process(pid);
            if let Some(proc) = sys.process(pid) {
                let mem = proc.memory();
                let prev = peak_mem_clone.load(std::sync::atomic::Ordering::Relaxed);
                if mem > prev {
                    peak_mem_clone.store(mem, std::sync::atomic::Ordering::Relaxed);
                }
            }
            std::thread::sleep(std::time::Duration::from_millis(10));
        }
    });

    let result = parallel_age_group_counts(&args[1], &args[2]);

    running.store(false, std::sync::atomic::Ordering::Relaxed);
    handle.join().unwrap();

    let elapsed = start.elapsed().as_millis();
    let peak_memory = peak_mem.load(std::sync::atomic::Ordering::Relaxed);
    let net_memory = peak_memory as i64 - base_memory as i64;

    println!(
        "peak m: {:.4} MB , net m: {:.4} MB , t: {} ms",
        peak_memory as f64 / 1024.0 / 1024.0,
        net_memory as f64 / 1024.0 / 1024.0,
        elapsed
    );

    if let Err(err) = result {
        eprintln!("Error: {}", err);
        std::process::exit(1);
    }

    Ok(())
}



