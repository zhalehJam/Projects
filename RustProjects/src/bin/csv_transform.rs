// Fast and clean CSV processor: filters users older than 30.

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
