module emul.m68k.instructions.rts;

import emul.m68k.instructions.create;

package pure nothrow:
void addRtsInstructions(ref Instruction[ushort] ret)
{
    //rts
    ret.addInstruction(Instruction("rts",0x4e75,0x2,&rtsImpl));
}

private:
@safe @nogc:
void rtsImpl(CpuPtr cpu)
{
    cpu.state.PC = cpu.memory.getValue!uint(cpu.state.SP);
    cpu.state.SP += uint.sizeof;
}