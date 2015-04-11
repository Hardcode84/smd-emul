module emul.cpu.instructions.move;

import emul.cpu.instructions.create;

package pure nothrow:
void addMoveInstructions(ref Instruction[ushort] ret)
{
    //move
    foreach(i,Type;TypeTuple!(byte,int,short))
    {
        enum Sz = i + 1;
        foreach(j; TupleRange!(0,writeAddressModes.length))
        {
            enum DestMode = writeAddressModes[j];
            static if(addressModeTraits!DestMode.Alterable)
            {
                foreach(k; TupleRange!(0,readAddressModes.length))
                {
                    enum SrcMode = readAddressModes[k];
                    enum instr = (Sz << 12) | (DestMode << 6) | SrcMode;
                    ret.addInstruction(Instruction("move",instr,0x2,&moveImpl!(Type,SrcMode)));
                }
            }
        }
    }
}

private:
void readFunc(T,ubyte Dest)(CpuPtr cpu, in T val)
{
    T writeFunc(CpuPtr cpu)
    {
        return val;
    }
    addressMode!(T,true,Dest,writeFunc)(cpu);
    updateFlags(cpu,val);
}

auto createReadFuncs(T)()
{
    void function(CpuPtr,in T) @nogc pure nothrow[] ret;
    foreach(j; TupleRange!(0,writeAddressModes.length))
    {
        enum DestMode = writeAddressModes[j];
        static if(addressModeTraits!DestMode.Alterable)
        {
            if(DestMode >= ret.length)
            {
                ret.length = DestMode + 1;
            }
            ret[DestMode] = &readFunc!(T,DestMode);
        }
    }

    return ret;
}

void moveImpl(T,ubyte Src)(CpuPtr cpu)
{
    const ubyte dest = (cpu.memory.getValue!ubyte(cpu.state.PC - 0x1) >> 6) & 0b111111;
    static immutable funcs = createReadFuncs!T();
    void readFuncThunk(CpuPtr cpu, in T val)
    {
        funcs[dest](cpu,val);
    }
    addressMode!(T,false,Src,readFuncThunk)(cpu);
}