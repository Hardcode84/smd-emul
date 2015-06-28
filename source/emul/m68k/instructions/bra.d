module emul.m68k.instructions.bra;

import emul.m68k.instructions.common;

package nothrow:
void addBraInstructions(ref Instruction[ushort] ret) pure
{
    //bra
    foreach(i; 0x1..0xff)
    {
        ret.addInstruction(Instruction("bra",cast(ushort)(0x6000 | i),0x2,&braImpl!void));
    }
    ret.addInstruction(Instruction("bra",0x6000,0x4,&braImpl!short));
    ret.addInstruction(Instruction("bra",0x60ff,0x6,&braImpl!int));
}

private:
void braImpl(T)(ref Cpu cpu)
{
    const offset = cpu.getInstructionData!T(cast(uint)(cpu.state.PC - T.sizeof));
    cpu.state.PC += offset - T.sizeof;
}
void braImpl(T : void)(ref Cpu cpu)
{
    const offset = cpu.getInstructionData!byte(cpu.state.PC - 0x1);
    cpu.state.PC += offset;
}