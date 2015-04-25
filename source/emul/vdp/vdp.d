module emul.vdp.vdp;

import gamelib.memory.saferef;
import gamelib.debugout;

import emul.m68k.cpu;

import emul.vdp.vdpstate;

final class Vdp
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
    ushort readHook(CpuPtr cpu, uint offset, Cpu.MemWordPart wpart)
    {
        debugfOut("vdp read : 0x%.6x 0x%.8x %s",cpu.state.PC,offset,wpart);
        assert(0x0 == (offset & 0x1));
        if(0xc00000 == offset || 0xc00002 == offset)
        {
            return readDataPort();
        }
        else if(0xc00004 == offset || 0xc00006 == offset)
        {
            return readControlPort();
        }
        else if(0xc00008 == offset || 0xc0000a == offset || 0xc0000c == offset || 0xc0000e == offset)
        {
            return readHVCounter();
        }
        assert(false);
    }
    void writeHook(CpuPtr cpu, uint offset, Cpu.MemWordPart wpart, ushort data)
    {
        debugfOut("vdp write : 0x%.6x 0x%.8x %s 0x%.4x",cpu.state.PC,offset,wpart,data);
        assert(0x0 == (offset & 0x1));
        if(wpart == Cpu.MemWordPart.LowerByte)
        {
            data = cast(ushort)(data | (data << 8));
        }
        else if(wpart == Cpu.MemWordPart.UpperByte)
        {
            data = cast(ushort)(data | (data >> 8));
        }

        if(0xc00000 == offset || 0xc00002 == offset)
        {
            return writeDataPort(data);
        }
        else if(0xc00004 == offset || 0xc00006 == offset)
        {
            return writeControlPort(data);
        }
        assert(false);
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
    ushort readDataPort()
    {
        //debugOut("read data");
        return 0;
    }
    void writeDataPort(ushort data)
    {
        //debugfOut("write data 0x%.4x",data);
    }
    ushort readControlPort()
    {
        //debugOut("read control");
        return mState.readControl();
    }
    void writeControlPort(ushort data)
    {
        //debugfOut("write control 0x%.4x",data);
        mState.writeControl(data);
    }
    ushort readHVCounter()
    {
        //debugOut("read HV counter");
        return 0;
    }

    VdpState mState;
}

alias VdpRef = SafeRef!Vdp;