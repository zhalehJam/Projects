// Fast and clean CSV processor: filters users older than 30.

use csv::{ReaderBuilder, WriterBuilder};
use serde::{Deserialize, Serialize};
use std::env;
use std::error::Error;
use std::process;
use std::time::Instant;
use sysinfo::{System, Process};

#[derive(Debug, Deserialize, Serialize)]
struct User {
    id: u32,
    name: String,
    email: String,
    age: u8,
}

fn run(input_path: &str, output_path: &str) -> Result<(), Box<dyn Error>> {
    let mut rdr = ReaderBuilder::new()
        .buffer_capacity(64 * 1024)
        .from_path(input_path)?;
    let mut wtr = WriterBuilder::new().from_path(output_path)?;

    // Stream and filter in a single pass, minimal allocations
    for result in rdr.deserialize() {
        let user: User = result?;
        if user.age > 30 {
            wtr.serialize(&user)?;
        }
    }

    wtr.flush()?;
    Ok(())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        eprintln!("Usage: csv_processor_rust <input.csv> <output.csv>");
        process::exit(1);
    }

    // Setup sysinfo for memory measurement
    let mut sys = System::new();
    sys.refresh_processes();
    let pid = sysinfo::get_current_pid().unwrap();
    let process = sys.process(pid).unwrap();
    let base_memory = process.memory(); 

    let start = Instant::now();

    // Optionally, spawn a thread to poll for peak memory
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

    let result = run(&args[1], &args[2]);

    running.store(false, std::sync::atomic::Ordering::Relaxed);
    handle.join().unwrap();

    let elapsed = start.elapsed().as_millis();
    let peak_memory = peak_mem.load(std::sync::atomic::Ordering::Relaxed);
    let net_memory = peak_memory as i64 - base_memory as i64;

    println!(
        "peak m: {:.4} MB , net m: {:.4} MB , t: {} ms",
        peak_memory as f64 / 1024.0/1024.0,
        net_memory as f64 / 1024.0 /1024.0,
        elapsed
    );

    if let Err(err) = result {
        eprintln!("Error processing CSV: {}", err);
        process::exit(1);
    }
}

/*
use csv::{ReaderBuilder, WriterBuilder};
use serde::{Deserialize, Serialize};
use std::env;
use std::error::Error;
use std::process;

#[derive(Debug, Deserialize, Serialize)]
struct User {
    id: u32,
    name: String,
    email: String,
    age: u8,
}

fn run(input_path: &str, output_path: &str) -> Result<(), Box<dyn Error>> {
    let mut rdr = ReaderBuilder::new()
        .buffer_capacity(64 * 1024)
        .from_path(input_path)?;
    let mut wtr = WriterBuilder::new().from_path(output_path)?;

    // Stream and filter in a single pass, minimal allocations
    for result in rdr.deserialize() {
        let user: User = result?;
        if user.age > 30 {
            wtr.serialize(&user)?;
        }
    }

    wtr.flush()?;
    Ok(())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        eprintln!("Usage: csv_processor_rust <input.csv> <output.csv>");
        process::exit(1);
    }
    if let Err(err) = run(&args[1], &args[2]) {
        eprintln!("Error processing CSV: {}", err);
        process::exit(1);
    }
}

*/