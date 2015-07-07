module emul.m68k.instructions.bsr;

import emul.m68k.instructions.common;

package nothrow:
void addBsrInstructions(ref Instruction[ushort] ret) pure
{
    foreach(i; 0x1..0xfe)
    {
        ret.addInstruction(Instruction("bsr",cast(ushort)(0x6100 | i),0x2,&bsrImpl!void));
    }
    ret.addInstruction(Instruction("bsr",0x6100,0x4,&bsrImpl!short));
    ret.addInstruction(Instruction("bsr",0x61ff,0x6,&bsrImpl!int));
}

private:
void bsrImpl(T)(ref Cpu cpu)
{
    cpu.state.SP -= uint.sizeof;
    cpu.setMemValue(cpu.state.SP,cpu.state.PC);
    const offset = cpu.getInstructionData!T(cast(uint)(cpu.state.PC - T.sizeof));
    cpu.state.PC += offset - T.sizeof;
}
void bsrImpl(T : void)(ref Cpu cpu)
{
    cpu.state.SP -= uint.sizeof;
    cpu.setMemValue(cpu.state.SP,cpu.state.PC);
    const offset = cpu.getInstructionData!byte(cpu.state.PC - 0x1);
    cpu.state.PC += offset;
}