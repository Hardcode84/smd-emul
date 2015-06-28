module emul.m68k.instructions.moveq;

import emul.m68k.instructions.common;

package nothrow:
void addMoveqInstructions(ref Instruction[ushort] ret) pure
{
    foreach(r; 0..8)
    {
        foreach(val; 0..0x100)
        {
            const instr = 0x7000 | (r << 9) | val;
            ret.addInstruction(Instruction("moveq",cast(ushort)instr,0x2,&moveqImpl!void));
        }
    }
}

private:
void moveqImpl(Dummy)(ref Cpu cpu)
{
    const word = cpu.getInstructionData!ushort(cpu.state.PC - 0x2);
    const reg = ((word >> 9) & 0b111);
    const data = cast(byte)(word & 0xff);
    cpu.state.D[reg] = data;
    updateFlags(cpu, data);
}