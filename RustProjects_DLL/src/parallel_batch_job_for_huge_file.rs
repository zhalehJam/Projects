//! Parallel batch job utilities for grouping users by age bracket from a CSV file.

use std::fs::File;
use polars::prelude::*;
use polars::lazy::dsl::{col, lit, count}; 
 
pub fn run_parallel_batch_job_inner_for_huge_file(input_path: &str, output_path: &str) -> Result<(), Box<dyn std::error::Error>> {
 
    // Limit Polars to 8 threads (optional tuning)
    unsafe { std::env::set_var("POLARS_MAX_THREADS", "8") };

    // Use Polars streaming lazy API for low memory and parallel groupby
    let lf = LazyCsvReader::new(input_path)
        .has_header(true)
        .finish()?; // returns LazyFrame
    
 
    let grouped = lf
        .with_columns([col("age").cast(DataType::UInt32)])
        .with_columns([
            (col("age") / lit(10u32)).cast(DataType::UInt32).alias("group"),
        ])
        .group_by([col("group")])
        .agg([count().alias("count")])
        .collect()?; // Use this if collect_streaming is not available

    let mut grouped = grouped;
    CsvWriter::new(File::create(output_path)?)
        .include_header(true)
        .finish(&mut grouped)?;


    Ok(())
}
