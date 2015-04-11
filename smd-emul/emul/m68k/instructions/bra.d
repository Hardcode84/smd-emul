module emul.m68k.instructions.bra;

import emul.m68k.instructions.create;

package pure nothrow:
void addBraInstructions(ref Instruction[ushort] ret)
{
    //bra
    foreach(i;TupleRange!(0x1,0xfe))
    {
        ret.addInstruction(Instruction("bra",0x6000 | i,0x2,&braBImpl!(cast(byte)i)));
    }
    ret.addInstruction(Instruction("bra",0x6000,0x4,&braImpl!short));
    ret.addInstruction(Instruction("bra",0x60ff,0x6,&braImpl!int));
}

private:
void braBImpl(byte offset)(CpuPtr cpu)
{
    cpu.state.PC += offset;
}
void braImpl(T)(CpuPtr cpu)
{
    const offset = cpu.memory.getValue!T(cpu.state.PC - T.sizeof);
    cpu.state.PC += offset;
}