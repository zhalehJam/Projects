// Run with:
// $ cargo run --bin batch_job large_input.csv output.csv
// Or optimized release build:
// $ cargo build --release --bin batch_job
// $ cargo run --release --bin batch_job large_input.csv output.csv

use std::env;
use std::error::Error;
use std::fs::File;
use std::io::BufReader;

use csv::{ReaderBuilder, WriterBuilder};
use serde::Deserialize;

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

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<String> = env::args().collect();

    // Validate CLI arguments
    if args.len() != 3 {
        eprintln!("Usage: batch_job <input.csv> <output.csv>");
        std::process::exit(1);
    }
 
    // Set up buffered CSV reader with a large buffer for performance
    let input_file = File::open(&args[1])?;
    let reader = BufReader::with_capacity(65536, input_file);
    let mut rdr = ReaderBuilder::new().has_headers(true).from_reader(reader);

    // Vec to hold counts per age group (0-9, 10-19, ..., 120-129)
    let mut counts: Vec<u32> = vec![0; 13]; // Supports ages 0-129

    // Read and count users by age group
    for result in rdr.deserialize::<User>() {
        let user = result?;
        let idx = age_group_index(user.age);
        if idx < counts.len() {
            counts[idx] += 1;
        }
    }

    // Write results to output CSV
    let output_file = File::create(&args[2])?;
    let mut wtr = WriterBuilder::new().from_writer(output_file);

    // Write CSV header
    wtr.write_record(&["age_group", "count"])?;

    // Write each age group and its count
    for (i, count) in counts.iter().enumerate() {
        let start = i * 10;
        let end = start + 9;
        wtr.write_record(&[format!("{}-{}", start, end), count.to_string()])?;
    }

    wtr.flush()?; // Ensure all data is written to disk
    Ok(())
}
// This code is a batch job that processes a CSV file containing user data, counts the number of users in each age group, and writes the results to a new CSV file.
// It uses the `csv` crate for efficient CSV handling and `serde` for deserialization.