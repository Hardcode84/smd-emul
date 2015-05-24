module emul.misc.misc;

import gamelib.memory.saferef;
import gamelib.debugout;

import emul.m68k.cpu;

final class Misc
{
public:
    this()
    {
        // Constructor code
    }

    void register(CpuPtr cpu) pure nothrow
    {
        cpu.addReadHook(&readHook,   0xa10000, 0xa10020);
        cpu.addWriteHook(&writeHook, 0xa10000, 0xa10020);
    }

private:
    ushort readHook(CpuPtr cpu, uint offset, Cpu.MemWordPart wpart) nothrow @nogc
    {
        debugfOut("misc read : 0x%.6x 0x%.8x %s",cpu.state.PC,offset,wpart);
        assert(0x0 == (offset & 0x1));
        return 0;
    }
    void writeHook(CpuPtr cpu, uint offset, Cpu.MemWordPart wpart, ushort data) nothrow @nogc
    {
        debugfOut("misc write : 0x%.6x 0x%.8x %s 0x%.4x",cpu.state.PC,offset,wpart,data);
        assert(0x0 == (offset & 0x1));
    }
}

alias MiscRef = SafeRef!Misc;

