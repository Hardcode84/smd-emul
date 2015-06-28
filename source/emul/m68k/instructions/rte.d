module emul.m68k.instructions.rte;

import emul.m68k.instructions.common;

package nothrow:
void addRteInstructions(ref Instruction[ushort] ret) pure
{
    //rte
    ret.addInstruction(Instruction("rte",0x4e73,0x2,&rteImpl!void));
}

private:
void rteImpl(Dummy)(ref Cpu cpu)
{
    //TODO: check priviledge mode
    returnFromException(cpu);
}