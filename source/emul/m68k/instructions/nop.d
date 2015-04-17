module emul.m68k.instructions.nop;

import emul.m68k.instructions.create;

package pure nothrow:
void addNoplInstructions(ref Instruction[ushort] ret)
{
    //nop
    ret.addInstruction(Instruction("nop",0x4e71,0x2,&nopImpl!void));
}

private:
void nopImpl(Dummy)(CpuPtr)
{
    //TODO
    import gamelib.debugout;
    debugOut("nop");
}