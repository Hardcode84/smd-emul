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
    uint D[8];
    uint A[8];
    auto ref SP() @property { return A[7]; }
    uint PC;
    ubyte CCR;
    void setFlags(CCRFlags flags) { CCR |= flags; }
    void clearFlags(CCRFlags flags) { CCR &= ~flags; }

    uint tickCounter = 0;
}

