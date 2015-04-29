module emul.m68k.instructions.anditosr;

import emul.m68k.instructions.common;

package nothrow:
void addAnditosrInstructions(ref Instruction[ushort] ret) pure
{
    ret.addInstruction(Instruction("andi to sr",0x027c,0x4,&anditosrImpl!void));
}

private:
void anditosrImpl(Dummy)(CpuPtr cpu)
{
    const val = cpu.getInstructionData!ushort(cast(uint)(cpu.state.PC - ushort.sizeof));
    cpu.state.SR = cpu.state.SR & val;
}