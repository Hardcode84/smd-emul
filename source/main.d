module main;

import gamelib.debugout;
import gamelib.memory.saferef;

import std.stdio;
import std.file;
import std.exception;
import std.path;
import std.algorithm;

import emul.rom;
import emul.core;

void main(string[] args)
{
    if( args.length <= 1 )
    {
        writeln("Hello World!");
        return;
    }

    const RomFormat format = args[1].extension.predSwitch(
        ".bin", RomFormat.BIN,
        ".md", RomFormat.MD,
        { enforce(false, "Unknown file extension"); }() );

    auto rom = createRom(format, read(args[1]).assumeUnique);
    writeln(rom.header);
    auto core = makeSafe!Core(rom);
    scope(exit) core.dispose();
    core.run();
}

