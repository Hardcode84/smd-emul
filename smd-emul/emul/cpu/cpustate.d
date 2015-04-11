module emul.cpu.cpustate;

enum CCRFlags
{
    C = 1 << 0, // Carry
    V = 1 << 1, // Overflow
    Z = 1 << 2, // Zero
    N = 1 << 3, // Negative
    X = 1 << 4, // Extend
}

struct CpuState
{
pure nothrow @nogc @safe:
    union
    {
        struct
        {
            int[8] D;
            uint[8] A;
        }
        uint[16] AllRegsU;
        int[16] AllregsS;
    }
    auto ref SP() inout @property { return A[7]; }
    uint PC;
    ubyte CCR;
    void setFlags(CCRFlags flags) { CCR |= flags; }
    void clearFlags(CCRFlags flags) { CCR &= ~flags; }
    bool testFlags(CCRFlags flags) const { return 0x0 != (CCR & flags); }

    uint tickCounter = 0;
}

