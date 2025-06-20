//! Parallel batch job utilities for grouping users by age bracket from a CSV file.

use std::error::Error;
use std::fs::File;
use std::io::BufReader;

use csv::{ReaderBuilder, StringRecord, WriterBuilder};
use rayon::prelude::*;
use serde::Deserialize;

/// Structure for deserializing each user row
#[derive(Debug, Deserialize)]
pub struct User {
    pub id: u32,
    pub name: String,
    pub email: String,
    pub age: u8,
}

/// Convert a raw age into a bucketed age group index (e.g., 30 → 3 for "30-39")
fn age_group_index(age: u8) -> usize {
    (age / 10) as usize
}

pub fn run_parallel_batch_job_inner(input_path: &str, output_path: &str) -> Result<(), Box<dyn Error>> {
    // We'll use 13 buckets for ages 0-129 (0-9, 10-19, ..., 120-129)
    const BUCKETS: usize = 13;
    let chunk_size = 1000;

    let input = File::open(input_path)?;
    let reader = BufReader::with_capacity(65536, input);
    let mut rdr = ReaderBuilder::new().has_headers(true).from_reader(reader);

    // Read header
    let headers = rdr.headers()?.clone();

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
    let mut wtr = WriterBuilder::new().from_writer(output_file);

    wtr.write_record(&["age_group", "count"])?;
    for (i, count) in global_counts.iter().enumerate() {
        let start = i * 10;
        let end = start + 9;
        wtr.write_record(&[format!("{}-{}", start, end), count.to_string()])?;
    }
    wtr.flush()?;
    Ok(())
}



// use polars::prelude::*;
// use polars::lazy::dsl::{col, lit, count};
// use serde::Deserialize;
// use std::fs::File;

// #[derive(Debug, Deserialize, Clone)]
// pub struct User {
//     pub id: u32,
//     pub name: String,
//     pub email: String,
//     pub age: u8,
// }
 
// pub fn run_parallel_batch_job_inner(input_path: &str, output_path: &str) -> Result<(), Box<dyn std::error::Error>> {
//     let df = CsvReader::from_path("results/huge_input.csv")?
//         .infer_schema(None)
//         .has_header(true)
//         .finish()?;

//     let grouped = df
//         .lazy()
//         .with_columns([col("age").cast(DataType::UInt32)])
//         .with_columns([
//             (col("age") / lit(10u32))
//                 .cast(DataType::UInt32)
//                 .alias("group"),
//         ])
//         .group_by([col("group")])
//         .agg([count().alias("count")])
//         .sort("group", Default::default())
//         .collect()?;

//     let mut grouped = grouped; // <- make mutable

//     CsvWriter::new(File::create("results/rustParallel_output_huge.csv")?)
//         .include_header(true)
//         .finish(&mut grouped)?;

//     Ok(())
// }
