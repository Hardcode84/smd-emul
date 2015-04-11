module emul.m68k.instructions.bcc;

import emul.m68k.instructions.create;

package pure nothrow:
void addBccInstructions(ref Instruction[ushort] ret)
{
    //bcc
    foreach(v; TupleRange!(0,conditionalTestsBcc.length))
    {
        enum cond = conditionalTestsBcc[v];
        enum instr = 0x6000 | (cast(ushort)cond << 8);
        foreach(i;TupleRange!(0x1,0xfe))
        {
            ret.addInstruction(Instruction("bcc",instr | i,0x2,&bccBImpl!(cond,cast(byte)i)));
        }
        ret.addInstruction(Instruction("bcc",instr | 0x00,0x4,&bccImpl!(cond,short)));
        ret.addInstruction(Instruction("bcc",instr | 0xff,0x6,&bccImpl!(cond,int)));
    }
}

private:
void bccBImpl(ubyte condition,byte offset)(CpuPtr cpu)
{
    if(conditionalTest!condition(cpu))
    {
        cpu.state.PC += offset;
    }
}
void bccImpl(ubyte condition,T)(CpuPtr cpu)
{
    if(conditionalTest!condition(cpu))
    {
        const offset = cpu.memory.getValue!T(cpu.state.PC - T.sizeof);
        cpu.state.PC += offset;
    }
}