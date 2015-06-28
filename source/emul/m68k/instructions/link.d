module emul.m68k.instructions.link;

import emul.m68k.instructions.common;

package nothrow:
void addLinkInstructions(ref Instruction[ushort] ret) pure
{
    foreach(r; TupleRange!(0,8))
    {
        ret.addInstruction(Instruction("link" ,0x4e50 | r,0x4,&linkImpl!r));
        ret.addInstruction(Instruction("linkl",0x4808 | r,0x6,&linklImpl!r));
    }
}

private:
void linkImpl(byte Reg)(ref Cpu cpu)
{
    const disp = cpu.getInstructionData!short(cpu.state.PC - 0x2);
    cpu.state.SP -= uint.sizeof;
    cpu.setMemValue(cpu.state.SP,cpu.state.A[Reg]);
    cpu.state.A[Reg] = cpu.state.SP;
    cpu.state.SP += disp;
}
void linklImpl(byte Reg)(ref Cpu cpu)
{
    const disp = cpu.getInstructionData!int(cpu.state.PC - 0x4);
    cpu.state.SP -= uint.sizeof;
    cpu.setMemValue(cpu.state.SP,cpu.state.A[Reg]);
    cpu.state.A[Reg] = cpu.state.SP;
    cpu.state.SP += disp;
}