use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

// fn main() {
//     let counter = Arc::new(Mutex::new(0));
//     let mut handles = vec![];

//     for _ in 0..1000 {
//         let counter = Arc::clone(&counter);
//         let handle = thread::spawn(move || {
//             for _ in 0..10 {
//                 // Wait to simulate race condition opportunity
//                 thread::sleep(Duration::from_millis(50));

//                 // Lock the counter for safe update
//                 let mut num = counter.lock().unwrap();
//                 *num += 1;
//             }
//         });

//         handles.push(handle);
//     }

//     for handle in handles {
//         handle.join().unwrap();
//     }

//     println!("Final counter (should be 10000): {}", *counter.lock().unwrap());
// }
// use std::thread;
// use std::time::Duration;

fn main() {
    let mut counter = 0; 

    let mut handles = vec![];

    for _ in 0..10 {
        let handle = thread::spawn(move|| {
            thread::sleep(Duration::from_millis(10));
            counter += 1; 
        });

        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }

    println!("Final counter: {}", counter);
}
