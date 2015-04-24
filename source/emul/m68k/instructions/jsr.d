module emul.m68k.instructions.jsr;

import emul.m68k.instructions.common;

package nothrow:
void addJsrInstructions(ref Instruction[ushort] ret) pure
{
    //jsr
    foreach(v; TupleRange!(0,readAddressModes.length))
    {
        enum mode = readAddressModes[v];
        static if(addressModeTraits!mode.Control)
        {
            ret.addInstruction(Instruction("jsr",0x4e80 | mode,0x2,&jsrImpl!mode));
        }
    }
}

private:
void jsrImpl(byte Mode)(CpuPtr cpu)
{
    addressMode!(uint,AddressModeType.ReadAddress,Mode,(cpu,b)
        {
            cpu.state.SP -= uint.sizeof;
            cpu.setMemValue(cpu.state.SP, cpu.state.PC);
            cpu.state.PC = b;
        })(cpu);
}