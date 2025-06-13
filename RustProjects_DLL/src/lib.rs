mod csv_transform;
mod batch_job;
mod parallel_batch_job;

use std::ffi::CStr;
use std::os::raw::c_char;

#[no_mangle]
pub extern "C" fn csv_transform(input: *const c_char, output: *const c_char) -> i32 {
    let input_cstr = unsafe { CStr::from_ptr(input) };
    let output_cstr = unsafe { CStr::from_ptr(output) };

    let input = input_cstr.to_str().unwrap_or_default();
    let output = output_cstr.to_str().unwrap_or_default();

    match csv_transform::csv_transform_inner(input, output) {
        Ok(_) => 0,
        Err(_) => 1,
    }
}

#[no_mangle]
pub extern "C" fn run_batch_job(input: *const c_char, output: *const c_char) -> i32 {
    let input_cstr = unsafe { CStr::from_ptr(input) };
    let output_cstr = unsafe { CStr::from_ptr(output) };

    let input = input_cstr.to_str().unwrap_or_default();
    let output = output_cstr.to_str().unwrap_or_default();

    match batch_job::run_batch_job_inner(input, output) {
        Ok(_) => 0,
        Err(_) => 1,
    }
}

#[no_mangle]
pub extern "C" fn run_parallel_batch_job(input: *const c_char, output: *const c_char) -> i32 {
    let input_cstr = unsafe { CStr::from_ptr(input) };
    let output_cstr = unsafe { CStr::from_ptr(output) };

    let input = input_cstr.to_str().unwrap_or_default();
    let output = output_cstr.to_str().unwrap_or_default();

    match parallel_batch_job::run_parallel_batch_job_inner(input, output) {
        Ok(_) => 0,
        Err(_) => 1,
    }
}





// pub fn add(left: u64, right: u64) -> u64 {
//     left + right
// }

// #[cfg(test)]
// mod tests {
//     use super::*;

//     #[test]
//     fn it_works() {
//         let result = add(2, 2);
//         assert_eq!(result, 4);
//     }
// }
// use std::ffi::{CStr, CString};
// use std::fs::{File};
// use std::io::{BufRead, BufReader, Write};
// use std::os::raw::c_char;

// #[no_mangle]
// pub extern "C" fn filter_csv(input_ptr: *const c_char, output_ptr: *const c_char) -> i32 {
//     // Convert C strings
//     let input_cstr = unsafe { CStr::from_ptr(input_ptr) };
//     let output_cstr = unsafe { CStr::from_ptr(outputPtr) };

//     let input = match input_cstr.to_str() {
//         Ok(s) => s,
//         Err(_) => return 1,
//     };
//     let output = match output_cstr.to_str() {
//         Ok(s) => s,
//         Err(_) => return 1,
//     };

//     if let Err(_) = do_filter(input, output) {
//         return 1;
//     }

//     0
// }

// fn do_filter(input_path: &str, output_path: &str) -> Result<(), Box<dyn std::error::Error>> {
//     let input = File::open(input_path)?;
//     let output = File::create(output_path)?;

//     let reader = BufReader::new(input);
//     let mut writer = std::io::BufWriter::new(output);

//     for line in reader.lines() {
//         let line = line?;
//         let parts: Vec<&str> = line.split(',').collect();

//         if parts.len() < 4 {
//             continue;
//         }

//         if let Ok(age) = parts[3].trim().parse::<u32>() {
//             if age > 30 {
//                 let name = parts[1].to_uppercase();
//                 let new_line = format!("{},{},{},{}", parts[0], name, parts[2], parts[3]);
//                 writeln!(writer, "{}", new_line)?;
//             }
//         }
//     }

//     writer.flush()?;
//     Ok(())
// }
