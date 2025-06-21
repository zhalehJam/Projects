//! Parallel batch job utilities for grouping users by age bracket from a CSV file.

use std::fs::File;
use polars::prelude::*;
use polars::lazy::dsl::{col, lit, count};

 
pub fn run_parallel_batch_job_inner_for_huge_file(input_path: &str, output_path: &str) -> Result<(), Box<dyn std::error::Error>> {
    let df = CsvReader::from_path(input_path)?
        .infer_schema(None)
        .has_header(true)
        .finish()?;

    let grouped = df
        .lazy()
        .with_columns([col("age").cast(DataType::UInt32)])
        .with_columns([
            (col("age") / lit(10u32))
                .cast(DataType::UInt32)
                .alias("group"),
        ])
        .group_by([col("group")])
        .agg([count().alias("count")])
        .sort("group", Default::default())
        .collect()?;

    let mut grouped = grouped; // <- make mutable

    CsvWriter::new(File::create(output_path)?)
        .include_header(true)
        .finish(&mut grouped)?;

    Ok(())
}
