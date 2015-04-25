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
    ushort[32] R;
    union
    {
        struct
        {
            ubyte HC;
            ubyte VC;
        }
        ushort HV;
    }
}

