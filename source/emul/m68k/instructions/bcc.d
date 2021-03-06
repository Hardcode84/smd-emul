﻿module emul.m68k.instructions.bcc;

import emul.m68k.instructions.common;

package nothrow:
void addBccInstructions(ref Instruction[ushort] ret) pure
{
    //bcc
    foreach(v; TupleRange!(0,conditionalTestsBcc.length))
    {
        enum cond = conditionalTestsBcc[v];
        enum instr = 0x6000 | (cast(ushort)cond << 8);
        foreach(i; 0x1..0xfe)
        {
            ret.addInstruction(Instruction("bcc",cast(ushort)(instr | i),0x2,&bccImpl!(cond,void)));
        }
        ret.addInstruction(Instruction("bcc",instr | 0x00,0x4,&bccImpl!(cond,short)));
        ret.addInstruction(Instruction("bcc",instr | 0xff,0x6,&bccImpl!(cond,int)));
    }
}

private:
void bccImpl(ubyte condition,T)(ref Cpu cpu)
{
    if(conditionalTest!condition(cpu))
    {
        const offset = cpu.getInstructionData!T(cast(uint)(cpu.state.PC - T.sizeof));
        cpu.state.PC += offset - T.sizeof;
    }
}
void bccImpl(ubyte condition,T : void)(ref Cpu cpu)
{
    if(conditionalTest!condition(cpu))
    {
        const offset = cpu.getInstructionData!byte(cpu.state.PC - 0x1);
        cpu.state.PC += offset;
    }
}