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

    void register(ref Cpu cpu) pure nothrow
    {
        cpu.addReadHook(&readHook,   0xa00000, 0xa0ffff);
        cpu.addWriteHook(&writeHook, 0xa00000, 0xa0ffff);
        cpu.addReadHook(&readHook,   0xa11100, 0xa11201);
        cpu.addWriteHook(&writeHook, 0xa11100, 0xa11201);
    }

private:
    bool mBusLocked = false;

    ushort readHook(ref Cpu cpu, uint offset, Cpu.MemWordPart wpart) nothrow @nogc
    {
        //debugfOut("z80 read : 0x%.6x 0x%.8x %s",cpu.state.PC,offset,wpart);
        assert(0x0 == (offset & 0x1));
        if(0xa11100 == offset)
        {
            ushort ret = 0;
            if(!mBusLocked)
            {
                ret |= 0x100;
            }
            return ret;
        }
        return 0;
    }
    void writeHook(ref Cpu cpu, uint offset, Cpu.MemWordPart wpart, ushort data) nothrow @nogc
    {
        //debugfOut("z80 write : 0x%.6x 0x%.8x %s 0x%.4x",cpu.state.PC,offset,wpart,data);
        assert(0x0 == (offset & 0x1));
        if(0xa11100 == offset)
        {
            mBusLocked = (0x0 != (data & 0x100));
            //debugOut("bus lock ",mBusLocked);
        }
        if(0xa11200 == offset)
        {
            if(0x0 != (data & 0x100))
            {
                //debugOut("reset");
            }
        }
    }
}

alias Z80Ref = SafeRef!Z80;