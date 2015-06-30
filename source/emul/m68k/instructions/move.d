module emul.m68k.instructions.move;

import emul.m68k.instructions.common;

package nothrow:
void addMoveInstructions(ref Instruction[ushort] ret) pure
{
    foreach(i,Type;TypeTuple!(byte,int,short))
    {
        enum Sz = i + 1;
        foreach(j; TupleRange!(0,writeAddressModes.length))
        {
            enum DestMode = writeAddressModes[j];
            static if(addressModeTraits!DestMode.Data && addressModeTraits!DestMode.Alterable)
            {
                foreach(k; TupleRange!(0,readAddressModes.length))
                {
                    enum SrcMode = readAddressModes[k];
                    enum instr = (Sz << 12) | ((DestMode & 0b111) << 9) | (((DestMode >> 3) & 0b111) << 6) | SrcMode;
                    ret.addInstruction(Instruction("move",instr,0x2,&moveImpl!(Type,SrcMode)));
                }
            }
        }
    }
}

private:
void readFunc(T,ubyte Dest)(ref Cpu cpu, in T val)
{
    T writeFunc(ref Cpu cpu)
    {
        return val;
    }
    addressMode!(T,AddressModeType.WriteDontExtendRegister,Dest,writeFunc)(cpu);
    updateFlags(cpu,val);
}

auto createReadFuncs(T)()
{
    void function(ref Cpu,in T) @nogc nothrow[] ret;
    foreach(j; TupleRange!(0,writeAddressModes.length))
    {
        enum DestMode = writeAddressModes[j];
        static if(addressModeTraits!DestMode.Data && addressModeTraits!DestMode.Alterable)
        {
            enum Dst = ((DestMode >> 3) & 0b111) | ((DestMode & 0b111) << 3);
            if(Dst >= ret.length)
            {
                ret.length = Dst + 1;
            }
            ret[Dst] = &readFunc!(T,DestMode);
        }
    }

    return ret;
}

void moveImpl(T,ubyte Src)(ref Cpu cpu)
{
    const dest = (cpu.getInstructionData!ushort(cpu.state.PC - 0x2) >> 6) & 0b111111;
    static immutable funcs = createReadFuncs!T();
    void readFuncThunk(ref Cpu cpu, in T val)
    {
        funcs[dest](cpu,val);
    }
    addressMode!(T,AddressModeType.Read,Src,readFuncThunk)(cpu);
}