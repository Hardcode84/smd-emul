module emul.vdp.vdpstate;

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
    ushort STATUS = 0x3400;

    void setFlags(VdpFlags flags)() { STATUS |= flags; }
    void clearFlags(VdpFlags flags)() { STATUS &= ~flags; }
    bool testFlags(VdpFlags flags)() const { return 0x0 != (STATUS & flags); }
    void setFlags(VdpFlags flags)(bool set) { if(set) setFlags!flags; else clearFlags!flags; }
}

