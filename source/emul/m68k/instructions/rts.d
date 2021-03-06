﻿module emul.m68k.instructions.rts;

import emul.m68k.instructions.common;

package nothrow:
void addRtsInstructions(ref Instruction[ushort] ret) pure
{
    //rts
    ret.addInstruction(Instruction("rts",0x4e75,0x2,&rtsImpl!void));
}

private:
void rtsImpl(Dummy)(ref Cpu cpu)
{
    cpu.state.PC = cpu.getMemValue!uint(cpu.state.SP);
    cpu.state.SP += uint.sizeof;
}