module emul.m68k.instructions.pea;

import emul.m68k.instructions.common;

package pure nothrow:
void addPeaInstructions(ref Instruction[ushort] ret)
{
    foreach(v; TupleRange!(0,readAddressModes.length))
    {
        enum mode = readAddressModes[v];
        if(addressModeTraits!mode.Control)
        {
            const instr = 0x4840 | mode;
            ret.addInstruction(Instruction("pea",cast(ushort)instr,0x2,&peaImpl!mode));
        }
    }
}

private:
void peaImpl(ubyte Mode)(CpuPtr cpu)
{
    addressMode!(uint,AddressModeType.ReadAddress,Mode,(cpu,val)
        {
            cpu.state.SP -= uint.sizeof;
            cpu.setMemValue(cpu.state.SP, val);
        })(cpu);
}