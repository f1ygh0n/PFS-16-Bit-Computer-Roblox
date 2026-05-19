# PFS-16-Bit-Computer-Roblox
This is a fully open source repository, which is a 16 bit computer simulated in roblox using real logic gates and binary. Updates are not expected to be regular.

## Use of each file

### ALU
Stores all ALU operations as functions(such as Add(), Sub(), Mul(), AND(), etc.), which can be accessed from a server script.
*Module Script*

### CPU_State
Stores the state of registers, memory, flags, running, mode, etc. Also has a function to reset everything inside the module to 0/nil/*default*
*Module Script*

### Parser
Parses the input of the player into commands, arguements and lines. Returns a table. Also stores all valid commands.
*Module Script*

### Interpreter
The most important module script. Receives the parsed input from the parser via the Main server script and decides what to do from each command and arguement.
For example, the command 'LOAD A 25' would be parsed into 'LOAD', 'A' and '25' in a table from the parser, and the interpreter will load 25 into the register A using an if statement.
*Module Script*

### Main
The heart of the computer. Receives the input from a local script via a RemoteEvent and calls all necessary module functions.
*Server Script*

### OutputManager
Receives the output from the interpreter, and formats it accordingly to print on a TextLabel.
*Local Script*

### ViewerManager
Receives data about registers, flags, program counter and memory in a table through the interpreter, and formats it to print on a TextLabel.
*Local Script*

## Current Supported Hardware
### 4-Digit 7-Segment Display
Load into memory address 1792 to display on the 7-Segment display in front using the command 'STORE *-your number here-* 1792'
*Note: Only 1-4 digit numbers are supported as of now*
