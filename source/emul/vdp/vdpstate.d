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

enum HScrollMode
{
    FullScreen = 0x0,
    FirstEightLines = 0x1,
    EveryRow = 0x2,
    EveryLine = 0x3,
}

enum VScrollMode
{
    FullScreen = 0x0,
    TwoCell = 0x1,
}

struct VdpState
{
pure nothrow @nogc @safe:
    ubyte[24] R;

    ushort Status = 0x3600;

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

    int TicksPerFrame;
    int TicksPerScan;
    int TicksPerRetrace;

    uint CurrentFrame = 0;
    int CurrentLine = 0;
    uint FrameStart = 0;
    int HInterruptCounter = 0;

    bool HBlankScheduled = false;
    bool VBlankScheduled = false;

    @property const
    {
        bool displayEnable() { return 0x0 == (R[0] & 0x1); }
        bool displayBlank() { return 0x0 == (R[1] & (1 << 6));}
        bool hInterruptEnabled() { return 0x0 != (R[0] & (1 << 4)); }
        bool vInterruptEnabled() { return 0x0 != (R[1] & (1 << 5)); }
        uint patternNameTableLayerA() { return (R[2] & 0b111000) << 10; }
        uint patternNameTableWindow() { return (R[3] & 0b111110) << 10;}
        uint patternnameTableLayerB() { return (R[4] & 0b111) << 13; }
        int layerWidth()
        {
            return 32 + 32 * (R[16] & 0b11);
        }
        int layerHeight()
        {
            return 32 + 32 * ((R[16] >> 4) & 0b11);
        }
        uint hScrollTableAddress() { return (R[13] & 0b111111) << 10; }
        HScrollMode hscrollMode() { return cast(HScrollMode)(R[11] & 0b11); }
        VScrollMode vscrollMode() { return cast(VScrollMode)((R[11] >> 3) & 0x1); }
        uint spriteAttributeTable() { return (R[5] & 0x7f) << 9;}
        auto backdropColor() { return cast(ubyte)(R[7] & 0b111_111); }
        auto interruptCounter() { return R[10]; }
        bool dmaEnabled() { return 0x0 != (R[1] & (1 << 4)); }
        bool wideDisplayMode() { return 0x0 != (R[12] & (1 << 7)); }
        bool tallDisplayMode() { return 0x0 != (R[7] & (1 << 3));}
        auto autoIncrement() { return R[15]; }
        auto dmaType()
        {
            if(0x0 == (R[23] & 0x80)) return DmaType.Transfer;
            else if(0x0 == (R[23] & 0x40)) return DmaType.Fill;
            else return DmaType.Copy;
        }
        auto dmaLen() { return R[19] | (R[20] << 8); }
        auto dmaSrcAddress()
        {
            assert(0x0 == (R[23] & 0x80));
            return (R[21] | (R[22] << 8) | (R[23] << 16)) << 1;
        }
    }

    void setFlags(VdpFlags flags)() { Status |= flags; }
    void clearFlags(VdpFlags flags)() { Status &= ~flags; }
    bool testFlags(VdpFlags flags)() const { return 0x0 != (Status & flags); }
    void setFlags(VdpFlags flags)(bool set) { if(set) setFlags!flags; else clearFlags!flags; }

}

