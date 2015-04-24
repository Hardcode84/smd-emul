module emul.m68k.instructions.unlink;

import emul.m68k.instructions.common;

package nothrow:
void addUnlinkInstructions(ref Instruction[ushort] ret) pure
{
    foreach(r; TupleRange!(0,8))
    {
        ret.addInstruction(Instruction("unlink" ,0x4e58 | r,0x2,&unlinkImpl!r));
    }
}

private:
void unlinkImpl(byte Reg)(CpuPtr cpu)
{
    cpu.state.SP = cpu.state.A[Reg];
    cpu.state.A[Reg] = cpu.getMemValue!uint(cpu.state.SP);
    cpu.state.SP += uint.sizeof;
}