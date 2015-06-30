module emul.m68k.instructions.movem;

import emul.m68k.instructions.common;

package nothrow:
void addMovemInstructions(ref Instruction[ushort] ret) pure
{
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
                static if((Write && addressModeTraits!mode.Control && addressModeTraits!mode.Alterable) ||
                          (!Write && addressModeTraits!mode.Control) ||
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
void movemImpl(ubyte dr, Type, ubyte mode)(ref Cpu cpu)
{
    import core.bitop;
    int*[16] regs = void;
    int** reg = regs.ptr;
    const uint mask = cpu.getInstructionData!ushort(cast(uint)(cpu.state.PC - ushort.sizeof));
    const count = popcnt(mask);
    enum W = (0 == dr ? AddressModeType.Write : AddressModeType.Read);
    static if(W == AddressModeType.Write)
    {
        auto func(ref Cpu cpu)
        {
            return cast(Type)(**(reg++));
        }
    }
    else
    {
        void func(ref Cpu cpu, in Type val)
        {
            **(reg++) = val;
        }
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
    foreach(val,ind;indices[])
    {
        if(0x0 != ((1 << val) & mask))
        {
            regs[i] = &cpu.state.AllregsS[ind];
            ++i;
        }
    }
    assert(i == count);
    addressMode!(Type,W,mode,func)(cpu,count);
}