module emul.m68k.instructions.illegal;

import emul.m68k.instructions.create;

package pure nothrow:
void addIllegalInstructions(ref Instruction[ushort] ret)
{
    //illegal
    ret.addInstruction(Instruction("illegal",0x4afc,0x2,&illegalImpl!void));
}

private:
void illegalImpl(Dummy)(CpuPtr cpu)
{
    //TODO
    import gamelib.debugout;
    debugOut("Illegal instruction");
    assert(false);
}