module emul.m68k.instructions.oritosr;

import emul.m68k.instructions.common;

package nothrow:
void addOritosrInstructions(ref Instruction[ushort] ret) pure
{
    //ori to sr
    ret.addInstruction(Instruction("ori to sr",0x007c,0x4,&oritosrImpl!void));
}

private:
void oritosrImpl(Dummy)(CpuPtr cpu)
{
    const val = cpu.getInstructionData!ushort(cast(uint)(cpu.state.PC - ushort.sizeof));
    cpu.state.SR = cpu.state.SR | val;
}