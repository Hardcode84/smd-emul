module emul.m68k.cpu.cpustate;

import std.algorithm;

import gamelib.debugout;

enum CCRFlags
{
    C = 1 << 0, // Carry
    V = 1 << 1, // Overflow
    Z = 1 << 2, // Zero
    N = 1 << 3, // Negative
    X = 1 << 4, // Extend
}

enum SRFlags
{
    I0 = 1 << 8,
    I1 = 1 << 9,
    I2 = 1 << 10,
    S  = 1 << 13,
    T  = 1 << 15,
}

struct CpuState
{
pure @safe:
    string toString() const
    {
        import std.array: appender;
        import std.format: formattedWrite;
        auto ret = appender!(char[])();
        foreach(i,val; D[])
        {
            formattedWrite(ret, "D%s  = 0x%.8x\n",i,val);
        }
        foreach(i,val; A[])
        {
            formattedWrite(ret, "A%s  = 0x%.8x\n",i,val);
        }
        formattedWrite(ret, "SP  = 0x%.8x\n",SP);
        formattedWrite(ret, "USP = 0x%.8x\n",USP);
        formattedWrite(ret, "SSP = 0x%.8x\n",SSP);
        formattedWrite(ret, "PC  = 0x%.8x\n",PC);
        formattedWrite(ret, "flags = 0x%.4x\n",SR);
        formattedWrite(ret, "ticks = %s",TickCounter);
        return ret.data;
    }
nothrow @nogc:
    union
    {
        struct
        {
            int[8] D;
            uint[8] A;
            private uint PrivateSP;
        }
        uint[16+1] AllRegsU;
        int[16+1] AllregsS;
    }
    auto ref SP() inout @property { return A[7]; }
    auto ref USP() inout @property { return AllRegsU[15 + ((SR >> 13) & 0x1)]; }
    auto ref SSP() inout @property { return AllRegsU[16 - ((SR >> 13) & 0x1)]; }
    uint PC;
    union
    {
        struct
        {
            ubyte CCR = void;
            ubyte SRupper = void;
        }
        private ushort PrivateSR = SRFlags.S;
    }
    void setFlags(CCRFlags flags)() { CCR |= flags; }
    void clearFlags(CCRFlags flags)() { CCR &= ~flags; }
    bool testFlags(CCRFlags flags)() const { return 0x0 != (CCR & flags); }
    void setFlags(CCRFlags flags)(bool set) { if(set) setFlags!flags; else clearFlags!flags; }

    auto SR() const @property { return PrivateSR; }
    void SR(ushort val) @property
    {
        const oldSR = PrivateSR;
        PrivateSR = val;
        if((oldSR & SRFlags.S) != (PrivateSR & SRFlags.S)) swap(A[7],PrivateSP);
    }

    void setFlags(SRFlags flags)()
    {
        const oldSR = PrivateSR;
        PrivateSR |= flags;
        if((0x0 != (flags & SRFlags.S)) && ((oldSR & SRFlags.S) != (PrivateSR & SRFlags.S))) swap(A[7],PrivateSP);
    }
    void clearFlags(SRFlags flags)()
    {
        const oldSR = PrivateSR;
        PrivateSR &= ~flags;
        if((0x0 != (flags & SRFlags.S)) && ((oldSR & SRFlags.S) != (PrivateSR & SRFlags.S))) swap(A[7],PrivateSP);
    }
    bool testFlags(SRFlags flags)() const
    {
        return 0x0 != (SR & flags); 
    }
    void setFlags(SRFlags flags)(bool set) { if(set) setFlags!flags; else clearFlags!flags; }

    @property void interruptLevel(ubyte level)
    {
        assert(level < 8);
        SRupper = cast(ubyte)((SRupper & ~0b111) | level);
    }
    @property byte interruptLevel() const
    {
        return cast(ubyte)(SRupper & 0b111);
    }

    uint TickCounter = 0;
}

