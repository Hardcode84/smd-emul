module emul.m68k.instructions.swap;

import emul.m68k.instructions.create;

package pure nothrow:
void addSwapInstructions(ref Instruction[ushort] ret)
{
    //swap
    foreach(r; TupleRange!(0,8))
    {
        ret.addInstruction(Instruction("swap",0x4840 | r,0x2,&swapImpl!r));
    }
}

private:
void swapImpl(ubyte Reg)(CpuPtr cpu)
{
    const uint val = cpu.state.D[Reg];
    const newVal = (val >> 16) | ((val & 0xffff) << 16);
    updateFlags(cpu,cast(int)newVal);
    cpu.state.D[Reg] = newVal;
}