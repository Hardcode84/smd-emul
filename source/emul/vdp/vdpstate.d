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

enum VdpCodeRegState
{
    VRamRead   = 0b0000,
    VRamWrite  = 0b0001,
    CRamWrite  = 0b0011,
    VSRamRead  = 0b0100,
    VSRamWrite = 0b0101,
    CRamRead   = 0b1000
}

enum DmaType
{
    Transfer,
    Fill,
    Copy
}

struct VdpState
{
pure nothrow @nogc @safe:
    ubyte[24] R;
    union
    {
        struct
        {
            ubyte HC;
            ubyte VC;
        }
        ushort HV;
    }

    ushort Status = 0x3400;

    uint AddressReg;
    VdpCodeRegState CodeReg = VdpCodeRegState.VRamRead;

    @property bool dmaEnabled() const { return 0x0 != (R[1] & (1 << 4)); }
    @property auto autoIncrement() const { return R[15]; }
    @property auto dmaType() const
    {
        if(0x0 == (R[23] & 0x80)) return DmaType.Transfer;
        else if(0x0 == (R[23] & 0x40)) return DmaType.Fill;
        else return DmaType.Copy;
    }
    @property auto dmaLen() const { return R[19] | (R[20] << 8); }
    @property auto dmaSrcAddress() const
    {
        assert(0x0 == (R[23] & 0x80));
        return R[21] | (R[22] << 8) | (R[23] << 16);
    }

    void setFlags(VdpFlags flags)() { status |= flags; }
    void clearFlags(VdpFlags flags)() { status &= ~flags; }
    bool testFlags(VdpFlags flags)() const { return 0x0 != (status & flags); }
    void setFlags(VdpFlags flags)(bool set) { if(set) setFlags!flags; else clearFlags!flags; }

}

