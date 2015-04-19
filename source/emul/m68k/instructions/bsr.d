module emul.m68k.instructions.bsr;

import emul.m68k.instructions.common;

package pure nothrow:
void addBsrInstructions(ref Instruction[ushort] ret)
{
    //bsr
    foreach(i; 0x1..0xfe)
    {
        ret.addInstruction(Instruction("bra",cast(ushort)(0x6100 | i),0x2,&bsrImpl!void));
    }
    ret.addInstruction(Instruction("bra",0x6100,0x4,&bsrImpl!short));
    ret.addInstruction(Instruction("bra",0x61ff,0x6,&bsrImpl!int));
}

private:
void bsrImpl(T)(CpuPtr cpu)
{
    cpu.state.SP -= uint.sizeof;
    cpu.setMemValue(cpu.state.SP,cpu.state.PC);
    const offset = cpu.getMemValueNoHook!T(cast(uint)(cpu.state.PC - T.sizeof));
    cpu.state.PC += offset - T.sizeof;
}
void bsrImpl(T : void)(CpuPtr cpu)
{
    cpu.state.SP -= uint.sizeof;
    cpu.setMemValue(cpu.state.SP,cpu.state.PC);
    const offset = cpu.getMemValueNoHook!byte(cpu.state.PC - 0x1);
    cpu.state.PC += offset;
}