module emul.m68k.instructions.exg;

import emul.m68k.instructions.common;

package nothrow:
void addExgInstructions(ref Instruction[ushort] ret) pure
{
    foreach(rx; TupleRange!(0,8))
    {
        foreach(ry; TupleRange!(0,8))
        {
            foreach(mode; TypeTuple!(0b01000,0b01001,0b10001))
            {
                const instr = 0xc100 | (rx << 9) | (mode << 3) | ry;
                ret.addInstruction(Instruction("exg",cast(ushort)instr,0x2,&exgImpl!(mode,rx,ry)));
            }
        }
    }
}

private:
void exgImpl(ubyte Mode, ubyte Ax, ubyte Ay)(ref Cpu cpu)
{
    static if(0b01000 == Mode)
    {
        if(Ax != Ay)
        {
            swap(cpu.state.D[Ax],cpu.state.D[Ay]);
        }
    }
    else static if(0b01001 == Mode)
    {
        if(Ax != Ay)
        {
            swap(cpu.state.A[Ax],cpu.state.A[Ay]);
        }
    }
    else static if(0b10001 == Mode)
    {
        const temp = cpu.state.D[Ax];
        cpu.state.D[Ax] = cpu.state.A[Ay];
        cpu.state.A[Ay] = temp;
    }
    else static assert(false, Mode);
}