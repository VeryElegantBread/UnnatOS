pub fn help() {
    println!(
        "
'-h' '--help' Prints this message!
'-n' '--new'  Follow with a path to create a new system there.
'-s' '--safe' Follow with a path to run in safe mode (doesn't run System/Startup.lua and uses System/Backups as the programs path instead of System/Programs)
path          Runs the system at that path.
    "
    )
}

