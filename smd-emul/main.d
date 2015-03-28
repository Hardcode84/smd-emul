module main;

import std.stdio;
import std.file;
import std.exception;

import emul.rom;

void main(string[] args)
{
    if( args.length <= 1 )
    {
        writeln("Hello World!");
        return;
    }
    
    auto rom = new Rom(read(args[1]).assumeUnique);
    writeln(rom.header);
}

