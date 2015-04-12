module emul.m68k.instructions.movea;

import emul.m68k.instructions.create;

package pure nothrow:
void addMoveaInstructions(ref Instruction[ushort] ret)
{
    //move
    foreach(i,Type;TypeTuple!(int,short))
    {
        enum Sz = i + 2;
        foreach(k; TupleRange!(0,readAddressModes.length))
        {
            enum SrcMode = readAddressModes[k];
            foreach(r; 0..8)
            {
                const instr = 0x40 | (Sz << 12) | (r << 9) | SrcMode;
                ret.addInstruction(Instruction("movea",cast(ushort)instr,0x2,&moveaImpl!(Type,SrcMode)));
            }
        }
    }
}

private:
void moveaImpl(T,ubyte Src)(CpuPtr cpu)
{
    const reg = (cpu.memory.getValue!ubyte(cpu.state.PC - 0x2) >> 1) & 0x1;
    void readFunc(CpuPtr cpu, in T val)
    {
        cpu.state.A[reg] = val;
    }
    addressMode!(T,AddressModeType.Read,Src,readFunc)(cpu);
}