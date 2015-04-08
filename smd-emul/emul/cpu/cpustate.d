module emul.cpu.cpustate;

struct CpuState
{
pure nothrow @nogc:
    uint D[8];
    uint A[8];
    auto ref SP() @property { return A[7]; }
    uint PC;
    ubyte CCR;

    uint tickCounter = 0;
}

