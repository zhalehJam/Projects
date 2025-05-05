use std::collections::BTreeMap;
use std::env;
use std::error::Error;
use std::fs::File;
use std::io::BufReader;

use csv::{ReaderBuilder, WriterBuilder};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
struct User {
    id: u32,
    name: String,
    email: String,
    age: u8,
}

fn age_group(age: u8) -> String {
    let base = (age / 10) * 10;
    format!("{}-{}", base, base + 9)
}

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        eprintln!("Usage: batch_job_rust <input.csv> <output.csv>");
        std::process::exit(1);
    }

    let input = File::open(&args[1])?;
    let reader = BufReader::new(input);
    let mut rdr = ReaderBuilder::new().from_reader(reader);

    let mut map: BTreeMap<String, u32> = BTreeMap::new();

    for result in rdr.deserialize::<User>() {
        let user = result?;
        let group = age_group(user.age);
        *map.entry(group).or_insert(0) += 1;
    }

    let output = File::create(&args[2])?;
    let mut wtr = WriterBuilder::new().from_writer(output);

    wtr.write_record(&["age_group", "count"])?;
    for (group, count) in map {
        wtr.write_record(&[group, count.to_string()])?;
    }

    wtr.flush()?;
    Ok(())
}

// use std::env;
// use std::error::Error;
// use std::fs::File;
// use std::process;

// use csv::{ReaderBuilder, WriterBuilder};
// use serde::{Deserialize, Serialize};

// #[derive(Debug, Deserialize, Serialize)]
// struct User {
//     id: u32,
//     name: String,
//     email: String,
//     age: u8,
// }

// fn run(input_path: &str, output_path: &str) -> Result<(), Box<dyn Error>> {
//     let mut rdr = ReaderBuilder::new().from_path(input_path)?;
//     let mut wtr = WriterBuilder::new().from_path(output_path)?;

//     for result in rdr.deserialize() {
//         let mut user: User = result?;
//         if user.age > 30 {
//             user.name = user.name.to_uppercase();
//             wtr.serialize(user)?;
//         }
//     }

//     wtr.flush()?;
//     Ok(())
// }

// fn main() {
//     let args: Vec<String> = env::args().collect();
//     if args.len() != 3 {
//         eprintln!("Usage: csv_processor_rust <input.csv> <output.csv>");
//         process::exit(1);
//     }

//     if let Err(err) = run(&args[1], &args[2]) {
//         eprintln!("Error processing CSV: {}", err);
//         process::exit(1);
//     }
// }
