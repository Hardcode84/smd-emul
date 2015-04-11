module emul.m68k.instructions.moveq;

import emul.m68k.instructions.create;

package pure nothrow:
void addMoveqInstructions(ref Instruction[ushort] ret)
{
    //moveq
    foreach(r; TupleRange!(0,8))
    {
        foreach(val; 0..0xff)
        {
            const instr = 0x7000 | (r << 9) | val;
            ret.addInstruction(Instruction("moveq",cast(ushort)instr,0x2,&moveqImpl!r));
        }
    }
}

private:
void moveqImpl(int Reg)(CpuPtr cpu)
{
    const int data = cpu.memory.getValue!byte(cpu.state.PC - 0x1);
    cpu.state.D[Reg] = data;
    updateFlags(cpu, data);
}