//! Batch job utilities for grouping users by age bracket from a CSV file.

use std::error::Error;
use std::fs::File;
use std::io::BufReader;

use csv::{ReaderBuilder, WriterBuilder};
use serde::Deserialize;

/// Struct to match the CSV input format
#[derive(Debug, Deserialize)]
pub struct User {
    pub id: u32,
    pub name: String,
    pub email: String,
    pub age: u8,
}

/// Convert age to a group index (e.g., 30 → 3 for "30-39")
fn age_group_index(age: u8) -> usize {
    (age / 10) as usize
}

pub fn run_batch_job_inner(input_path: &str, output_path: &str) -> Result<(), Box<dyn Error>> {
    // Set up buffered CSV reader with a large buffer for performance
    let input_file = File::open(input_path)?;
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
    let output_file = File::create(output_path)?;
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