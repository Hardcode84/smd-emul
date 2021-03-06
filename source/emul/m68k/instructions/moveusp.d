﻿module emul.m68k.instructions.moveusp;

import emul.m68k.instructions.common;

package nothrow:
void addMoveuspInstructions(ref Instruction[ushort] ret) pure
{
    //move
    foreach(dr; TupleRange!(0,2))
    {
        foreach(r; 0..8)
        {
            const instr = 0x4e60 | (dr << 3) | r;
            ret.addInstruction(Instruction("move usp",cast(ushort)instr,0x2,&moveuspImpl!dr));
        }
    }
}

private:
void moveuspImpl(ubyte dr)(ref Cpu cpu)
{
    const reg = cpu.getInstructionData!ubyte(cpu.state.PC - 0x1) & 0b111;
    static if(0 == dr)
    {
        cpu.state.USP = cpu.state.A[reg];
    }
    else
    {
        cpu.state.A[reg] = cpu.state.USP;
    }
}