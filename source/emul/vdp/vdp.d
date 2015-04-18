module emul.vdp.vdp;

import gamelib.memory.saferef;
import gamelib.debugout;

import emul.m68k.cpu;

struct Vdp
{
public:
pure nothrow:

    void register(CpuPtr cpu)
    {
        cpu.addReadHook(&readHook, 0xc00000, 0xc0000A);
        cpu.addWriteHook(&writeHook, 0xc00000, 0xc0000A);
    }

private:
@nogc:
    uint readHook(CpuPtr cpu, uint offset, size_t size)
    {
        debugfOut("read : 0x%.6x 0x%.8x 0x%x",cpu.state.PC,offset,size);
        return 0;
    }
    void writeHook(CpuPtr cpu, uint offset, size_t size, uint data)
    {
        debugfOut("write : 0x%.6x 0x%.8x 0x%x 0x%.8x",cpu.state.PC,offset,size,data);
    }
}

alias VpdPtr = SafeRef!Vdp;