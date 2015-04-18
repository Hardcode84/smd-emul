module emul.m68k.instructions.dbcc;

import emul.m68k.instructions.create;

package pure nothrow:
void addDbccInstructions(ref Instruction[ushort] ret)
{
    //bcc
    foreach(v; TupleRange!(0,conditionalTests.length))
    {
        enum cond = conditionalTests[v];
        foreach(r;0..8)
        {
            const instr = 0x50c8 | (cond << 8) | r;
            ret.addInstruction(Instruction("dbcc",cast(ushort)instr,0x4,&dbccImpl!cond));
        }
    }
}

private:

void dbccImpl(ubyte condition)(CpuPtr cpu)
{
    if(!conditionalTest!condition(cpu))
    {
        const reg = cpu.getMemValue!ubyte(cpu.state.PC - 0x3) & 0b111;
        cpu.state.D[reg] = (cpu.state.D[reg] - 1);
        if(-1 != cpu.state.D[reg])
        {
            const offset = cpu.getMemValue!short(cpu.state.PC - 0x2);
            cpu.state.PC += offset - 0x2;
        }
    }
}