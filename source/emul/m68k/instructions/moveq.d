module emul.m68k.instructions.moveq;

import emul.m68k.instructions.common;

package pure nothrow:
void addMoveqInstructions(ref Instruction[ushort] ret)
{
    //moveq
    foreach(r; 0..8)
    {
        foreach(val; 0..0xff)
        {
            const instr = 0x7000 | (r << 9) | val;
            ret.addInstruction(Instruction("moveq",cast(ushort)instr,0x2,&moveqImpl!void));
        }
    }
}

private:
void moveqImpl(Dummy)(CpuPtr cpu)
{
    const reg = ((cpu.getMemValueNoHook!ubyte(cpu.state.PC - 0x2) >> 1) & 0b111);
    const int data = cpu.getMemValueNoHook!byte(cpu.state.PC - 0x1);
    cpu.state.D[reg] = data;
    updateFlags(cpu, data);
}