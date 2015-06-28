module emul.m68k.instructions.ext;

import emul.m68k.instructions.common;

package nothrow:
void addExtInstructions(ref Instruction[ushort] ret) pure
{
    foreach(r; TupleRange!(0,8))
    {
        foreach(mode; TypeTuple!(0b010,0b011,0b111))
        {
            static if(0b010 == mode)
            {
                alias SrcT = byte;
                alias DstT = short;
            }
            else static if(0b011 == mode)
            {
                alias SrcT = short;
                alias DstT = int;
            }
            else static if(0b111 == mode)
            {
                alias SrcT = byte;
                alias DstT = int;
            }
            else static assert(false);
            ret.addInstruction(Instruction("ext",0x4800 | (mode << 6) | r,0x2,&extImpl!(SrcT,DstT,r)));
        }
    }
}

private:
void extImpl(SrcT,DstT,ubyte Reg)(ref Cpu cpu)
{
    static assert(DstT.sizeof > SrcT.sizeof);
    truncateReg!DstT(cpu.state.D[Reg]) = truncateReg!SrcT(cpu.state.D[Reg]);
    updateFlags(cpu,truncateReg!DstT(cpu.state.D[Reg]));
}