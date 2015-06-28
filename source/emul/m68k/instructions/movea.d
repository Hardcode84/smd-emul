module emul.m68k.instructions.movea;

import emul.m68k.instructions.common;

package nothrow:
void addMoveaInstructions(ref Instruction[ushort] ret) pure
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
void moveaImpl(T,ubyte Src)(ref Cpu cpu)
{
    const reg = (cpu.getInstructionData!ubyte(cpu.state.PC - 0x2) >> 1) & 0b111;
    void readFunc(ref Cpu cpu, in T val)
    {
        cpu.state.A[reg] = val;
    }
    addressMode!(T,AddressModeType.Read,Src,readFunc)(cpu);
}