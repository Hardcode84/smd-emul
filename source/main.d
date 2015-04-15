module main;

import gamelib.memory.saferef;

import std.stdio;
import std.file;
import std.exception;

import emul.rom;
import emul.m68k.cpurunner;

void main(string[] args)
{
    if( args.length <= 1 )
    {
        writeln("Hello World!");
        return;
    }
    
    auto rom = makeSafe!Rom(read(args[1]).assumeUnique);
    writeln(rom.header);
    auto runner = makeSafe!CpuRunner(rom);
    runner.run();
}

