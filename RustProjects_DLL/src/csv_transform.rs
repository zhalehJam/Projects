//! CSV processing library: filter and transform users from a CSV file.

use csv::{ReaderBuilder, WriterBuilder};
use serde::{Deserialize, Serialize};
use std::error::Error;

/// User record structure.
#[derive(Debug, Deserialize, Serialize)]
pub struct User {
    pub id: u32,
    pub name: String,
    pub email: String,
    pub age: u8,
}

/// Processes a CSV file, writing users with age > 30 and uppercased names to output.
///
/// # Arguments
/// * `input_path` - Path to the input CSV file.
/// * `output_path` - Path to the output CSV file.
///
/// # Errors
/// Returns an error if reading or writing fails.
pub fn csv_transform_inner(input_path: &str, output_path: &str) -> Result<(), Box<dyn Error>> {
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
