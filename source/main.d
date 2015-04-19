module main;

import gamelib.debugout;
import gamelib.memory.saferef;

import std.stdio;
import std.file;
import std.exception;

import emul.rom;
import emul.core;

void main(string[] args)
{
    if( args.length <= 1 )
    {
        writeln("Hello World!");
        return;
    }

    auto rom = makeSafe!Rom(read(args[1]).assumeUnique);
    writeln(rom.header);
    auto core = makeSafe!Core(rom);
    core.run();
}

