module emul.m68k.instructions.cmp;

import emul.m68k.instructions.common;
import emul.m68k.instructions.arith;

package nothrow:
void addCmpInstructions(ref Instruction[ushort] ret) pure
{
    foreach(v; TupleRange!(0,readAddressModesWSize.length))
    {
        enum mode = readAddressModesWSize[v];
        foreach(r; TupleRange!(0,8))
        {
            const instr = 0xb000 | (r << 9) | mode;
            ret.addInstruction(Instruction("cmp",cast(ushort)instr,0x2,&cmpImpl!(r,mode)));
        }
    }
}

private:
void cmpImpl(ubyte Reg,ubyte Mode)(CpuPtr cpu)
{
    alias Type = sizeField!(Mode >> 6);
    addressModeWSize!(AddressModeType.Read,Mode,(cpu,val)
        {
            cast(void)sub_no_x(cast(Type)cpu.state.D[Reg], val, cpu);
        })(cpu);
}