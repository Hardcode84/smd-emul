module emul.z80.z80;

import gamelib.memory.saferef;
import gamelib.debugout;

import emul.m68k.cpu;

final class Z80
{
public:
    this()
    {
        // Constructor code
    }

    void register(CpuPtr cpu) pure nothrow
    {
        cpu.addReadHook(&readHook,   0xa00000, 0xa0ffff);
        cpu.addWriteHook(&writeHook, 0xa00000, 0xa0ffff);
        cpu.addReadHook(&readHook,   0xa11100, 0xa11201);
        cpu.addWriteHook(&writeHook, 0xa11100, 0xa11201);
    }

private:
    ushort readHook(CpuPtr cpu, uint offset, Cpu.MemWordPart wpart) nothrow @nogc
    {
        debugfOut("z80 read : 0x%.6x 0x%.8x %s",cpu.state.PC,offset,wpart);
        assert(0x0 == (offset & 0x1));
        return 0;
    }
    void writeHook(CpuPtr cpu, uint offset, Cpu.MemWordPart wpart, ushort data) nothrow @nogc
    {
        debugfOut("z80 write : 0x%.6x 0x%.8x %s 0x%.4x",cpu.state.PC,offset,wpart,data);
        assert(0x0 == (offset & 0x1));
    }
}

alias Z80Ref = SafeRef!Z80;