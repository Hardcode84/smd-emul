module emul.misc.misc;

import gamelib.memory.saferef;
import gamelib.debugout;
import gamelib.core;
import gamelib.types;

import emul.settings;

import emul.m68k.cpu;

final class Misc
{
public:
    enum IoPortPins
    {
        UP    = 1 << 0,
        DOWN  = 1 << 1,
        LEFT  = 1 << 2,
        RIGHT = 1 << 3,
        TR    = 1 << 4,
        TL    = 1 << 5,
        TH    = 1 << 6
    }
    enum IoPortDirection
    {
        Read, Write
    }
    alias IoPortHook = ubyte delegate(in ref Cpu, IoPortDirection, ubyte, ubyte) nothrow @nogc;

    struct IoSettings
    {
        IoPortHook[3] ioHooks;
    }

    this(in Settings settings, in IoSettings ioSettings)
    {
        const val = (settings.model << 7) |
                ((settings.vmode == DisplayFormat.NTSC ? 0 : 1) << 6) |
                (1 << 5) |
                (settings.consoleVer & 0b1111);
        mVersionReg = cast(ushort)val;

        ubyte defHandler(in ref Cpu, IoPortDirection, ubyte, ubyte) nothrow @nogc
        {
            return 0;
        }

        foreach(i;0..3)
        {
            mIoPorts[i].setHook(ioSettings.ioHooks[i] !is null ? ioSettings.ioHooks[i] : &defHandler);
        }
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
        //debugfOut("misc read : 0x%.6x 0x%.8x %s",cpu.state.PC,offset,wpart);
        assert(0x0 == (offset & 0x1));
        if(0xa10000 == offset)
        {
            return mVersionReg;
        }
        else if(offset >= 0xa10002 && offset <= 0xa10018)
        {
            const val = readIo(cpu,offset);
            return val | (val << 8);
        }
        return 0;
    }
    void writeHook(ref Cpu cpu, uint offset, Cpu.MemWordPart wpart, ushort data) nothrow @nogc
    {
        //debugfOut("misc write : 0x%.6x 0x%.8x %s 0x%.4x",cpu.state.PC,offset,wpart,data);
        assert(0x0 == (offset & 0x1));
        if(offset >= 0xa10002 && offset <= 0xa10018)
        {
            writeIo(cpu,offset,cast(ubyte)data);
        }
    }

    ubyte readIo(in ref Cpu cpu, uint offset) nothrow @nogc
    {
        if(offset < 0xa10008)
        {
            const ind = (offset - 0xa10002) / 2;
            return mIoPorts[ind].readData(cpu);
        }
        else if(offset < 0xa1000e)
        {
            const ind = (offset - 0xa10008) / 2;
            return mIoPorts[ind].readCtrl();
        }
        assert(false);
    }

    void writeIo(in ref Cpu cpu, uint offset, ubyte data) nothrow @nogc
    {
        if(offset < 0xa10008)
        {
            const ind = (offset - 0xa10002) / 2;
            return mIoPorts[ind].writeData(cpu, data);
        }
        else if(offset < 0xa1000e)
        {
            const ind = (offset - 0xa10008) / 2;
            return mIoPorts[ind].writeCtrl(data);
        }
        else assert(false);
    }

    struct IoPort
    {
    nothrow @nogc:
        void writeData(in ref Cpu cpu, ubyte val)
        {
            mData = val;
            mHook(cpu, IoPortDirection.Write, mData, mCtrl);
        }
        ubyte readData(in ref Cpu cpu) const
        {
            ubyte ret = mData & 0x80;
            //ret |= (~mCtrl) & 0x7f;
            ret |= mHook(cpu, IoPortDirection.Read, mData, mCtrl);
            //debugfOut("ret: 0x%x",ret);
            return ret;
        }
        void writeCtrl(ubyte val) { mCtrl = val; }
        ubyte readCtrl() const { return mCtrl; }
        void setHook(in IoPortHook hook) { mHook = hook; }
    private:
        IoPortHook mHook;
        ubyte mData;
        ubyte mCtrl;
    }
    IoPort[3] mIoPorts;
}

alias MiscRef = SafeRef!Misc;

