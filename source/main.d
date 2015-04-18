module main;

import gamelib.debugout;
import gamelib.memory.saferef;

import std.stdio;
import std.file;
import std.exception;

import emul.rom;
import emul.m68k.cpurunner;
import emul.m68k.cpu;

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
    CpuRunner.RunParams params;
    params.breakHandlers[CpuRunner.BreakReason.SingleStep] = (CpuPtr cpu)
    {
        if(cpu.state.tickCounter > 3000_000)
        {
            debugOut(cpu.state);
            return false;
        }
        return true;
    };
    runner.run(params);
}

