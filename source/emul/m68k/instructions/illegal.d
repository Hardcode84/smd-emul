module emul.m68k.instructions.illegal;

import emul.m68k.instructions.common;

package nothrow:
void addIllegalInstructions(ref Instruction[ushort] ret) pure
{
    //illegal
    ret.addInstruction(Instruction("illegal",0x4afc,0x2,&illegalImpl!void));

    //line 1111 emulation
    foreach(i; 0x0..0x1000)
    {
        ret.addInstruction(Instruction("line1111",cast(ushort)(0xf000 | i),0x2,&e1111Impl!void));
    }

    //line 1010 emulation
    foreach(i; 0x0..0x1000)
    {
        ret.addInstruction(Instruction("line1010",cast(ushort)(0xa000 | i),0x2,&e1010Impl!void));
    }
}

private:
void illegalImpl(Dummy)(ref Cpu cpu)
{
    //TODO
    import gamelib.debugout;
    debugOut("Illegal instruction");
    cpu.triggerException(ExceptionCodes.Illegal_instruction);
    assert(false);
}

void e1111Impl(Dummy)(ref Cpu cpu)
{
    //TODO
    import gamelib.debugout;
    debugOut("1111 line emulator");
    cpu.triggerException(ExceptionCodes.LINE_1111_EMULATOR);
    assert(false);
}

void e1010Impl(Dummy)(ref Cpu cpu)
{
    //TODO
    import gamelib.debugout;
    debugOut("1010 line emulator");
    cpu.triggerException(ExceptionCodes.LINE_1010_EMULATOR);
    assert(false);
}