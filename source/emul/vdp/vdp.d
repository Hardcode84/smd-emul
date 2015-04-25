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
        cpu.addReadHook(&readHook,   0xc00000, 0xc0000A);
        cpu.addWriteHook(&writeHook, 0xc00000, 0xc0000A);
        cpu.setInterruptsHook(&interruptsHook);
    }

private:
@nogc:
    ushort readHook(CpuPtr cpu, uint offset, bool isByte)
    {
        debugfOut("vdp read : 0x%.6x 0x%.8x %s",cpu.state.PC,offset,isByte);
        return 0;
    }
    void writeHook(CpuPtr cpu, uint offset, bool isByte, ushort data)
    {
        debugfOut("vdp write : 0x%.6x 0x%.8x %s 0x%.8x",cpu.state.PC,offset,isByte,data);
    }
    void interruptsHook(const CpuPtr cpu, ref Exceptions e)
    {
        if((cpu.state.tickCounter - mCounter) < 100_000)
        {
            //debugOut("hblank");
            //e.setInterrupt(ExceptionCodes.IRQ_4);
            mCounter = cpu.state.tickCounter;
        }
    }
    int mCounter = 0;
}

alias VpdPtr = SafeRef!Vdp;