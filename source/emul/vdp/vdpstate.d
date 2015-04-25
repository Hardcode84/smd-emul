module emul.vdp.vdpstate;

import gamelib.debugout;

enum VdpFlags
{
    PalMode           = 1 << 0,
    DmaInProgress     = 1 << 1,
    HBlank            = 1 << 2,
    VBlank            = 1 << 3,
    OddFrame          = 1 << 4,
    SpriteCollision   = 1 << 5,
    SpriteOverflow    = 1 << 6,
    VInterruptPending = 1 << 7,
    FIFOFull          = 1 << 8,
    FIFIEmpty         = 1 << 9
}

struct VdpState
{
pure nothrow @nogc @safe:
    ubyte[23] R;
    union
    {
        struct
        {
            ubyte HC;
            ubyte VC;
        }
        ushort HV;
    }

    void setFlags(VdpFlags flags)() { status |= flags; }
    void clearFlags(VdpFlags flags)() { status &= ~flags; }
    bool testFlags(VdpFlags flags)() const { return 0x0 != (status & flags); }
    void setFlags(VdpFlags flags)(bool set) { if(set) setFlags!flags; else clearFlags!flags; }

    ushort readControl()
    {
        flushControl();
        return status;
    }

    void writeControl(ushort data)
    {
        if(pendingControlWrite)
        {
            pendingControlBuff[1] = data;
            flushControl();
        }
        else if(0x8000 == (data & 0xc000))
        {
            const reg = (data >> 8) & 0b11111;
            const val = cast(ubyte)(data & 0xff);
            debugfOut("vdp reg %s 0x%.2x",reg,val);
            if(reg < R.length)
            {
                R[reg] = val;
            }
        }
        else
        {
            pendingControlBuff[0] = data;
            pendingControlWrite = true;
        }
    }

private:
    ushort status = 0x3400;
    bool pendingControlWrite = false;
    ushort[2] pendingControlBuff;
    uint addressReg;
    uint codeReg;

    void flushControl()
    {
        addressReg = (pendingControlBuff[0] & ~0xc000) | (pendingControlBuff[1] << 14);
        codeReg = (pendingControlBuff[0] >> 14) | ((pendingControlBuff[1] >> 2) & 0b111111);
        debugfOut("flushControl ar=0x%.8x cr=0x%x",addressReg,codeReg);
        pendingControlWrite = false;
    }
}

