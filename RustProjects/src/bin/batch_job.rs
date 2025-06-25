// Run with:
// $ cargo run --bin batch_job large_input.csv output.csv
// Or optimized release build:
// $ cargo build --release --bin batch_job
// $ cargo run --release --bin batch_job large_input.csv output.csv

use std::env;
use std::error::Error;
use std::fs::File;
use std::io::BufReader;
use std::time::Instant;

use csv::{ReaderBuilder, WriterBuilder};
use serde::Deserialize;
use sysinfo::{System, Process};

/// Struct to match the CSV input format
#[derive(Debug, Deserialize)]
struct User {
    id: u32,
    name: String,
    email: String,
    age: u8,
}

/// Convert age to a bracketed group index (e.g., 30 → 3 for "30-39")
fn age_group_index(age: u8) -> usize {
    (age / 10) as usize
}

/// Core logic: reads input CSV, counts users by age group, writes summary to output CSV
fn process_age_groups(input_path: &str, output_path: &str) -> Result<(), Box<dyn Error>> {
    let input_file = File::open(input_path)?;
    let reader = BufReader::with_capacity(65536, input_file);
    let mut rdr = ReaderBuilder::new().has_headers(true).from_reader(reader);

    let mut counts: Vec<u32> = vec![0; 13]; // Supports ages 0-129

    for result in rdr.deserialize::<User>() {
        let user = result?;
        let idx = age_group_index(user.age);
        if idx < counts.len() {
            counts[idx] += 1;
        }
    }

    let output_file = File::create(output_path)?;
    let mut wtr = WriterBuilder::new().from_writer(output_file);

    wtr.write_record(&["age_group", "count"])?;
    for (i, count) in counts.iter().enumerate() {
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
        eprintln!("Usage: batch_job <input.csv> <output.csv>");
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

    let result = process_age_groups(&args[1], &args[2]);

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