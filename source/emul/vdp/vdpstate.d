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

    ushort Status = 0x3400;

    uint AddressReg;
    VdpCodeRegState CodeReg = VdpCodeRegState.VRamRead;

    int TotalWidth;
    int TotalHeight;
    int StartLine;
    int EndLine;
    int CellWidth;
    int CellHeight;
    int Width;
    int Height;

    uint TicksPerScan;
    uint TicksPerRetrace;

    int CurrentLine = 0;
    uint FrameStart = 0;
    int HInterruptCounter = 0;

    bool HBlankScheduled = false;
    bool VBlankScheduled = false;

    @property bool displayEnable() const { return 0x0 != (R[0] & 0x1); }
    @property bool displayBlank() const { return 0x0 != (R[1] & (1 << 6));}
    @property bool hInterruptEnabled() const { return 0x0 != (R[0] & (1 << 4)); }
    @property bool vInterruptEnabled() const { return 0x0 != (R[1] & (1 << 5)); }
    @property auto backdropColor() const { return cast(ubyte)(R[7] & 0b111_111); }
    @property auto interruptCounter() const { return R[10]; }
    @property bool dmaEnabled() const { return 0x0 != (R[1] & (1 << 4)); }
    @property bool wideDisplayMode() const { return 0x0 != (R[12] & (1 << 7)); }
    @property bool tallDisplayMode() const { return 0x0 != (R[7] & (1 << 3));}
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

    void setFlags(VdpFlags flags)() { Status |= flags; }
    void clearFlags(VdpFlags flags)() { Status &= ~flags; }
    bool testFlags(VdpFlags flags)() const { return 0x0 != (Status & flags); }
    void setFlags(VdpFlags flags)(bool set) { if(set) setFlags!flags; else clearFlags!flags; }

}

