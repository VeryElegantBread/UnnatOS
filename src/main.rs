use std::{env::args, sync::{Arc, Mutex}} ;

mod filesystem;
use filesystem::*;
mod save_file;
use save_file::*;
mod misc;
use misc::*;
mod lua;
use lua::*;

fn main() {
    let args: Vec<String> = args().collect();

    if args.len() == 1 {
        println!("You need to put a path. '-h' for help.");
        return;
    }

    let safe;
    let file_system;
    let root;
    let mut path = args[1].as_str();
    match path {
        "-h" | "--help" => { help(); return; },
        "-n" | "--new" => {
            if args.len() == 2 {
                println!("You need to put a path. '-h' for help.");
                return;
            }
            new(&args[2]);
            return;
        }
        "-s" | "--safe" => {
            if args.len() == 2 {
                println!("You need to put a path. '-h' for help.");
                return;
            };
            path = args[2].as_str();
            (file_system, root) = load_file_system(path).expect("There were errors loading the file.");
            safe = true;
        },
        _ => {
            (file_system, root) = load_file_system(path).expect("There were errors loading the file.");
            safe = false;
        },
    }

    let mut arc_file_system = Arc::new(Mutex::new(file_system));
    if let Err(error) = run(&mut arc_file_system, root, path, safe) {
        eprintln!("Error: {}", format_lua_error(&error));
    }
}
