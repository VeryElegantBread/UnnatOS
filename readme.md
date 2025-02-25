# UnnatOS
UnnatOS is a sort of pseudo-os written in rust where files and directories are one in the same. One item contains both text and more items. The shell and all programs are written in lua and are accessible in the OS.
## Installation
1. Install Rust and Cargo
   https://rustup.rs/
2. Clone the repository
	```
	git clone https://github.com/VeryElegantBread/UnnatOS
	```
3. Build
	```
	cd UnnatOS
	cargo build --release
	```
4. Locate the compiled program
   It should be at UnnatOS/target/release/UnnatOS you may want to move it to a place where you can run it easily.
## Usage
To create a base OS, run `UnnatOS -n path/to/where/you/want/the/OS/to/be/saved`
After that, you can run `UnnatOS path/to/where/you/saved/it`
Once in the OS, you can run `help` to view all the default commands. Those commands are stored in System/Programs and you can edit the code for all of them or add new ones.
The cool part about UnnatOS is that you can easily customize it a lot. If you don't like how a command works, just change how it works. If you want a command that doesn't exist, just make it exist. I you don't like how the shell works, just make a new shell and run it in System/Startup.lua. All of it is just A bit of lua code away. That being said, the default `write` command requires you to put \n for newlines, which can make it hard to think about how the code you're typing in works, debug it, and copy and paste in code. While I encourage you to make your own solutions to problems like this, it can be hard to make a solution with the default write command. So, if you want a better way of putting text into an item, put these commands into UnnatOS and then use the `textwriter` command to put text into an item.
```
download https://raw.githubusercontent.com/VeryElegantBread/UnnatOS-Programs/main/textwriter.lua System/Programs/textwriter
se System/Programs/textwriter
```
## Customization
Pretty much anything about the command line can be customized with lua. While the default shell is immutable, you can view how it works, write your own, and start it in System/Startup.lua. All the commands are in System/Programs and you can change them or make new ones. The easiest way to program things for it right now is probably to code them in another text editor and then copy and paste them into the textwriter program installed with the commands above. I recommend you always save before running a program you made.
## Items
Each item can contain more items and text and has a value called executability, which determines if the shell will let you run them, since running a file that doesn't contain proper lua code could crash the system. They also have a value called mutability but only a few files that are necessary for the system have that on.
The structure of the default system is as follows.
```
root
└── System
	├── Shell.lua
	├── Startup.lua
	├── Programs
	│   ├── read
	│   ├── items
	│   ├── exit
	│   ├── new
	│   ├── remove
	│   ├── save
	│   ├── se
	│   └── write
	└── Backups
	    ├── read
	    ├── items
	    ├── exit
	    ├── new
	    ├── remove
	    ├── save
	    ├── se
	    └── write
```
Yes, they are the same items in Programs and Backups. The ones in Backups are immutable incase you mess up the ones in Programs.
## What to do if you messed up something in your system
Run `UnnatOS -s path/to/your/file`. This will put you in safe mode, which doesn't run Startup.lua and uses the programs in Backups instead of Programs. From there, you can fix the issue.
