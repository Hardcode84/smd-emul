module emul.misc.misc;

import gamelib.memory.saferef;
import gamelib.debugout;

import emul.settings;

import emul.m68k.cpu;

struct MiscSettings
{
    Model model = Model.Overseas;
    DisplayFormat vmode = DisplayFormat.NTSC;
    ubyte ver = 0;
}

final class Misc
{
public:
    this(in MiscSettings settings = MiscSettings())
    {
        const val = (settings.model << 15) | (settings.vmode << 14) | (1 << 13) | ((settings.ver & 0b111) << 8);
        assert(0 == (val & 0xffff0000));
        mVersionReg = cast(ushort)val;
    }

    void register(ref Cpu cpu) pure nothrow
    {
        cpu.addReadHook(&readHook,   0xa10000, 0xa10020);
        cpu.addWriteHook(&writeHook, 0xa10000, 0xa10020);
        cpu.addReadHook(&readHook,   0xc00011, 0xc00012);
        cpu.addWriteHook(&writeHook, 0xc00011, 0xc00012);
    }

private:
    const ushort mVersionReg;

    ushort readHook(ref Cpu cpu, uint offset, Cpu.MemWordPart wpart) nothrow @nogc
    {
        debugfOut("misc read : 0x%.6x 0x%.8x %s",cpu.state.PC,offset,wpart);
        assert(0x0 == (offset & 0x1));
        if(0xa10000 == offset)
        {
            return mVersionReg;
        }
        return 0;
    }
    void writeHook(ref Cpu cpu, uint offset, Cpu.MemWordPart wpart, ushort data) nothrow @nogc
    {
        debugfOut("misc write : 0x%.6x 0x%.8x %s 0x%.4x",cpu.state.PC,offset,wpart,data);
        assert(0x0 == (offset & 0x1));
    }
}

alias MiscRef = SafeRef!Misc;

