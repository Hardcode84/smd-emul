module emul.m68k.instructions.bra;

import emul.m68k.instructions.common;

package pure nothrow:
void addBraInstructions(ref Instruction[ushort] ret)
{
    //bra
    foreach(i; 0x1..0xfe)
    {
        ret.addInstruction(Instruction("bra",cast(ushort)(0x6000 | i),0x2,&braImpl!void));
    }
    ret.addInstruction(Instruction("bra",0x6000,0x4,&braImpl!short));
    ret.addInstruction(Instruction("bra",0x60ff,0x6,&braImpl!int));
}

private:
void braImpl(T)(CpuPtr cpu)
{
    const offset = cpu.getMemValueNoHook!T(cast(uint)(cpu.state.PC - T.sizeof));
    cpu.state.PC += offset - T.sizeof;
}
void braImpl(T : void)(CpuPtr cpu)
{
    const offset = cpu.getMemValueNoHook!byte(cpu.state.PC - 0x1);
    cpu.state.PC += offset;
}