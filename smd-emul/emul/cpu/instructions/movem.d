module emul.cpu.instructions.movem;

import emul.cpu.instructions.create;

package pure nothrow:
void addMovemInstructions(ref Instruction[ushort] ret)
{
    //movem
    foreach(s,T; TypeTuple!(short,int))
    {
        foreach(dr; TupleRange!(0,2))
        {
            enum Write = (0 == dr);
            static if(Write)
            {
                alias modes = writeAddressModes;
            }
            else
            {
                alias modes = readAddressModes;
            }
            foreach(v; TupleRange!(0,modes.length))
            {
                enum mode = modes[v];
                if(addressModeTraits!mode.Control ||
                    (Write && addressModeTraits!mode.Predecrement) ||
                    (!Write && addressModeTraits!mode.Postincrement))
                {
                    enum instr = 0x4880 | (dr << 10) | (s << 6) | mode;
                    ret.addInstruction(Instruction("movem",instr,0x4,&movemImpl!(dr,T,mode)));
                }
            }
        }
    }
}

private:
void movemImpl(ubyte dr, Type, ubyte mode)(CpuPtr cpu)
{
    import core.bitop;
    int*[16] regs = void;
    int** reg = regs.ptr;
    const uint mask = cpu.memory.getValue!ushort(cpu.state.PC - ushort.sizeof);
    const count = popcnt(mask);
    enum Write = (0 == dr);
    static if(Write)
    {
        auto func(CpuPtr cpu) { return cast(Type)(**(reg++)); }
    }
    else
    {
        void func(CpuPtr cpu, in Type val) { **(reg++) = val; }
    }
    static if(addressModeTraits!mode.Predecrement)
    {
        static immutable indices = iota(16).retro.array;
    }
    else
    {
        static immutable indices = iota(16).array;
    }
    int i = 0;
    foreach(ind;indices[])
    {
        if(0x0 != ((1 << ind) & mask))
        {
            regs[i] = &cpu.state.AllregsS[ind];
            ++i;
        }
    }
    addressMode!(Type,Write,mode,func)(cpu);
}