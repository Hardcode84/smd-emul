module emul.m68k.instructions.oritoccr;

import emul.m68k.instructions.common;

package nothrow:
void addOritoccrInstructions(ref Instruction[ushort] ret) pure
{
    ret.addInstruction(Instruction("ori to ccr",0x003c,0x4,&oritoccrImpl!void));
}

private:
void oritoccrImpl(Dummy)(CpuPtr cpu)
{
    const val = cpu.getInstructionData!ubyte(cast(uint)(cpu.state.PC - ubyte.sizeof));
    cpu.state.CCR = cpu.state.CCR | val;
}