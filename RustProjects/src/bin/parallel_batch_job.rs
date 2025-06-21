// Build: cargo build --release --bin batch_job_parallel

use std::env;
use std::error::Error;
use std::fs::File;
use std::io::BufReader;

use csv::{ReaderBuilder, StringRecord};
use rayon::prelude::*;
use serde::Deserialize;

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

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        eprintln!("Usage: batch_job_parallel <input.csv> <output.csv>");
        std::process::exit(1);
    }

    let input = File::open(&args[1])?;
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
    let output_file = File::create(&args[2])?;
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



